use image::DynamicImage;
use rustler::{types::atom::nil, Resource, ResourceArc};
use std::sync::Mutex;

rustler::atoms! {
    // ditherer names
    floyd_steinberg,
    atkinson,
    stucki,
    burkes,
    jarvis,
    sierra,

    // dither types
    bw,

    // flip directions
    horizontal,
    vertical,
    both,

    // image formats
    avif,
    bmp,
    exr,
    ff,
    farbfeld,
    gif,
    hdr,
    ico,
    jpeg,
    png,
    pnm,
    qoi,
    tga,
    tiff,
    webp,

    // errors
    invalid_buffer
}

pub struct ImageResource {
    pub inner: Mutex<DynamicImage>,
}

#[rustler::resource_impl]
impl Resource for ImageResource {}

pub type ImageArc = ResourceArc<ImageResource>;

pub struct ImageFormatWrapper(pub image::ImageFormat);

impl<'a> rustler::Decoder<'a> for ImageFormatWrapper {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        let atom: rustler::Atom = term.decode()?;
        let format = match atom {
            x if x == avif() => image::ImageFormat::Avif,
            x if x == bmp() => image::ImageFormat::Bmp,
            x if x == exr() => image::ImageFormat::OpenExr,
            x if x == ff() || x == farbfeld() => image::ImageFormat::Farbfeld,
            x if x == gif() => image::ImageFormat::Gif,
            x if x == hdr() => image::ImageFormat::Hdr,
            x if x == ico() => image::ImageFormat::Ico,
            x if x == jpeg() => image::ImageFormat::Jpeg,
            x if x == png() => image::ImageFormat::Png,
            x if x == pnm() => image::ImageFormat::Pnm,
            x if x == qoi() => image::ImageFormat::Qoi,
            x if x == tga() => image::ImageFormat::Tga,
            x if x == tiff() => image::ImageFormat::Tiff,
            x if x == webp() => image::ImageFormat::WebP,
            _ => return Err(rustler::Error::BadArg),
        };
        Ok(ImageFormatWrapper(format))
    }
}

#[derive(Debug)]
pub enum DitherAlgorithm {
    FloydSteinberg,
    Atkinson,
    Stucki,
    Burkes,
    Jarvis,
    Sierra,
}

impl<'a> rustler::Decoder<'a> for DitherAlgorithm {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        let atom: rustler::Atom = term.decode()?;
        match atom {
            x if x == floyd_steinberg() => Ok(DitherAlgorithm::FloydSteinberg),
            x if x == atkinson() => Ok(DitherAlgorithm::Atkinson),
            x if x == stucki() => Ok(DitherAlgorithm::Stucki),
            x if x == burkes() => Ok(DitherAlgorithm::Burkes),
            x if x == jarvis() => Ok(DitherAlgorithm::Jarvis),
            x if x == sierra() => Ok(DitherAlgorithm::Sierra),
            _ => Err(rustler::Error::BadArg),
        }
    }
}

#[derive(Debug)]
pub enum DitherType {
    BlackAndWhite,
    Color(Vec<(u8, u8, u8)>),
}

impl<'a> rustler::Decoder<'a> for DitherType {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        if let Ok(atom) = term.decode::<rustler::Atom>() {
            if atom == bw() {
                return Ok(DitherType::BlackAndWhite);
            }
        }

        if let Ok((tag, palette)) = term.decode::<(rustler::Atom, Vec<(u8, u8, u8)>)>() {
            if tag == crate::color() {
                return Ok(DitherType::Color(palette));
            }
        }

        Err(rustler::Error::BadArg)
    }
}

#[derive(Debug)]
pub enum FlipDirection {
    None,
    Horizontal,
    Vertical,
    Both,
}

impl<'a> rustler::Decoder<'a> for FlipDirection {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        let atom: rustler::Atom = term.decode()?;
        match atom {
            x if x == nil() => Ok(FlipDirection::None),
            x if x == horizontal() => Ok(FlipDirection::Horizontal),
            x if x == vertical() => Ok(FlipDirection::Vertical),
            x if x == both() => Ok(FlipDirection::Both),
            _ => Err(rustler::Error::BadArg),
        }
    }
}

#[derive(Debug)]
pub enum RotateDegrees {
    D90,
    D180,
    D270,
}

impl<'a> rustler::Decoder<'a> for RotateDegrees {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        let degrees: u32 = term.decode()?;
        match degrees {
            90 => Ok(RotateDegrees::D90),
            180 => Ok(RotateDegrees::D180),
            270 => Ok(RotateDegrees::D270),
            _ => Err(rustler::Error::BadArg),
        }
    }
}
