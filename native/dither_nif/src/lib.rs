use std::{
    io::Cursor,
    sync::{Mutex, PoisonError},
};

use crate::dither::{dither_color, dither_grayscale};
use image::{
    imageops::FilterType, ColorType, DynamicImage, GenericImageView, GrayImage, ImageDecoder,
    ImageError, RgbImage, RgbaImage,
};
use rustler::{Atom, Binary, Env, NewBinary, Term};
use types::{
    invalid_buffer, DitherAlgorithm, DitherType, FlipDirection, ImageArc, ImageFormatWrapper,
    ImageResource, RotateDegrees,
};

mod dither;
mod types;

rustler::atoms! {
    image_decode_failed,
    image_encode_failed,
    io_error,
    invalid_parameter,
    resource_limit,
    unsupported,

    // success/failure
    success,
    failed_to_acquire_mutex,

    // dithering modes
    color
}

#[rustler::nif]
fn load(path: String) -> Result<ImageArc, Atom> {
    let reader = image::ImageReader::open(&path)
        .map_err(ImageError::IoError)
        .map_err(handle_image_error)?;
    let mut decoder = reader.into_decoder().map_err(handle_image_error)?;
    let orientation = decoder.orientation().map_err(handle_image_error)?;
    let mut img = DynamicImage::from_decoder(decoder).map_err(handle_image_error)?;
    img.apply_orientation(orientation);

    match img.color() {
        ColorType::L8 | ColorType::Rgb8 | ColorType::Rgba8 => {}
        _ => return Err(image_decode_failed()),
    }

    let img_resource = ImageResource {
        inner: Mutex::new(img),
    };

    Ok(ImageArc::new(img_resource))
}

#[rustler::nif]
fn save(img: ImageArc, path: String) -> Result<Atom, Atom> {
    let locked = img.inner.lock().map_err(handle_mutex_error)?;
    locked.save(path).map_err(handle_image_error)?;
    Ok(success())
}

#[rustler::nif]
fn decode(encoded: Binary) -> Result<ImageArc, Atom> {
    let reader = image::ImageReader::new(Cursor::new(encoded.as_slice()))
        .with_guessed_format()
        .map_err(ImageError::IoError)
        .map_err(handle_image_error)?;
    let mut decoder = reader.into_decoder().map_err(handle_image_error)?;
    let orientation = decoder.orientation().map_err(handle_image_error)?;
    let mut img = DynamicImage::from_decoder(decoder).map_err(handle_image_error)?;
    img.apply_orientation(orientation);

    let img_resource = ImageResource {
        inner: Mutex::new(img),
    };
    Ok(ImageArc::new(img_resource))
}

#[rustler::nif]
fn encode<'a>(env: Env<'a>, img: ImageArc, format: ImageFormatWrapper) -> Result<Term<'a>, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    let mut bytes: Vec<u8> = Vec::new();

    img_lock
        .clone()
        .write_to(&mut Cursor::new(&mut bytes), format.0)
        .map_err(handle_image_error)?;

    let mut binary = NewBinary::new(env, bytes.len());
    binary.as_mut_slice().copy_from_slice(bytes.as_slice());

    Ok(binary.into())
}

#[rustler::nif]
fn from_raw<'a>(bytes: Binary<'a>, width: u32, height: u32) -> Result<ImageArc, Atom> {
    let img: DynamicImage;

    if bytes.len() == (width * height) as usize {
        img = DynamicImage::ImageLuma8(
            GrayImage::from_raw(width, height, bytes.as_slice().into()).ok_or(invalid_buffer())?,
        );
    } else if bytes.len() == (3 * width * height) as usize {
        img = DynamicImage::ImageRgb8(
            RgbImage::from_raw(width, height, bytes.as_slice().into()).ok_or(invalid_buffer())?,
        );
    } else if bytes.len() == (4 * width * height) as usize {
        img = DynamicImage::ImageRgba8(
            RgbaImage::from_raw(width, height, bytes.as_slice().into()).ok_or(invalid_buffer())?,
        );
    } else {
        return Err(invalid_buffer());
    }

    let img_resource = ImageResource {
        inner: Mutex::new(img),
    };

    Ok(ImageArc::new(img_resource))
}

#[rustler::nif]
fn to_raw<'a>(env: Env<'a>, img: ImageArc) -> Result<Term<'a>, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    let bytes = img_lock.clone().into_bytes();

    let mut binary = NewBinary::new(env, bytes.len());
    binary.copy_from_slice(bytes.as_slice());

    Ok(binary.into())
}

#[rustler::nif]
fn resize(img: ImageArc, width: u32, height: u32) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    let img_resized = img_lock.resize_to_fill(width, height, FilterType::Triangle);
    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(img_resized),
    }))
}

#[rustler::nif]
fn grayscale(img: ImageArc) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(DynamicImage::ImageLuma8(img_lock.to_luma8())),
    }))
}

#[rustler::nif]
fn to_rgb(img: ImageArc) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(DynamicImage::ImageRgb8(img_lock.to_rgb8())),
    }))
}

#[rustler::nif]
fn rotate(img: ImageArc, degrees: RotateDegrees) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;

    let img_rotated = match degrees {
        RotateDegrees::D90 => img_lock.rotate90(),
        RotateDegrees::D180 => img_lock.rotate180(),
        RotateDegrees::D270 => img_lock.rotate270(),
    };

    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(img_rotated),
    }))
}

#[rustler::nif]
fn flip(img: ImageArc, direction: FlipDirection) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;

    let img_flipped = match direction {
        FlipDirection::None => img_lock.clone(),
        FlipDirection::Horizontal => img_lock.clone().fliph(),
        FlipDirection::Vertical => img_lock.clone().flipv(),
        FlipDirection::Both => img_lock.clone().flipv().fliph(),
    };

    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(img_flipped),
    }))
}

#[rustler::nif]
fn dimensions(img: ImageArc) -> Result<(u32, u32), Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    Ok(img_lock.dimensions())
}

#[rustler::nif]
fn channels(img: ImageArc) -> Result<u32, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    match img_lock.color() {
        ColorType::L8 => Ok(1),
        ColorType::Rgb8 => Ok(3),
        ColorType::Rgba8 => Ok(4),
        _ => Err(unsupported()),
    }
}

#[rustler::nif]
fn contrast(img: ImageArc, factor: f32) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;
    let img_adjusted = img_lock.adjust_contrast(factor);

    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(img_adjusted),
    }))
}

#[rustler::nif]
fn dither(
    img: ImageArc,
    dither_type: DitherType,
    algorithm: DitherAlgorithm,
    depth: u8,
) -> Result<ImageArc, Atom> {
    let img_lock = img.inner.lock().map_err(handle_mutex_error)?;

    let img_dithered: DynamicImage;

    match dither_type {
        DitherType::BlackAndWhite => {
            img_dithered = dither_grayscale(&img_lock, algorithm, depth);
        }
        DitherType::Color(palette) => {
            img_dithered = dither_color(&img_lock, algorithm, palette);
        }
    }

    Ok(ImageArc::new(ImageResource {
        inner: Mutex::new(img_dithered),
    }))
}

fn handle_image_error(err: ImageError) -> Atom {
    match err {
        ImageError::Decoding(_) => image_decode_failed(),
        ImageError::Encoding(_) => image_encode_failed(),
        ImageError::IoError(_) => io_error(),
        ImageError::Unsupported(_) => unsupported(),
        ImageError::Parameter(_) => invalid_parameter(),
        ImageError::Limits(_) => resource_limit(),
    }
}

fn handle_mutex_error<T>(_err: PoisonError<T>) -> Atom {
    failed_to_acquire_mutex()
}

rustler::init!("Elixir.Dither.NIF");
