use dither_lib::{
    clamp_f64_to_u8, create_quantize_n_bits_func,
    ditherer::{
        atkinson_ditherer, burkes_ditherer, floyd_steinberg_ditherer, jarvis_ditherer,
        sierra3_ditherer, stucki_ditherer, Dither,
    },
    img::Img,
};
use image::{DynamicImage, GrayImage, RgbImage};

use crate::types::DitherAlgorithm;

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct RGBf64(pub [f64; 3]);

impl std::ops::Add for RGBf64 {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        RGBf64([
            self.0[0] + rhs.0[0],
            self.0[1] + rhs.0[1],
            self.0[2] + rhs.0[2],
        ])
    }
}

impl std::ops::Sub for RGBf64 {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        RGBf64([
            self.0[0] - rhs.0[0],
            self.0[1] - rhs.0[1],
            self.0[2] - rhs.0[2],
        ])
    }
}

impl std::ops::Mul<f64> for RGBf64 {
    type Output = Self;
    fn mul(self, rhs: f64) -> Self {
        RGBf64([self.0[0] * rhs, self.0[1] * rhs, self.0[2] * rhs])
    }
}

impl std::ops::Div<f64> for RGBf64 {
    type Output = Self;
    fn div(self, rhs: f64) -> Self {
        RGBf64([self.0[0] / rhs, self.0[1] / rhs, self.0[2] / rhs])
    }
}

pub fn dither_grayscale(
    image: &DynamicImage,
    algorithm: DitherAlgorithm,
    depth: u8,
) -> DynamicImage {
    let ditherer = match algorithm {
        DitherAlgorithm::FloydSteinberg => floyd_steinberg_ditherer(),
        DitherAlgorithm::Atkinson => atkinson_ditherer(),
        DitherAlgorithm::Stucki => stucki_ditherer(),
        DitherAlgorithm::Burkes => burkes_ditherer(),
        DitherAlgorithm::Jarvis => jarvis_ditherer(),
        DitherAlgorithm::Sierra => sierra3_ditherer(),
    };

    let quantize = create_quantize_n_bits_func(depth).unwrap();

    let img = Img::<u8>::new(image.to_luma8().into_raw(), image.width())
        .unwrap()
        .convert_with(f64::from);

    let dithered = ditherer.dither(img, quantize);
    let w = dithered.width();
    let h = dithered.height();
    let dithered_u8 = dithered.convert_with(clamp_f64_to_u8).into_vec();

    let result = GrayImage::from_raw(w, h, dithered_u8).unwrap();
    DynamicImage::ImageLuma8(result)
}

pub fn dither_color(
    image: &DynamicImage,
    algorithm: DitherAlgorithm,
    palette: Vec<(u8, u8, u8)>,
) -> DynamicImage {
    let ditherer = match algorithm {
        DitherAlgorithm::FloydSteinberg => floyd_steinberg_ditherer(),
        DitherAlgorithm::Atkinson => atkinson_ditherer(),
        DitherAlgorithm::Stucki => stucki_ditherer(),
        DitherAlgorithm::Burkes => burkes_ditherer(),
        DitherAlgorithm::Jarvis => jarvis_ditherer(),
        DitherAlgorithm::Sierra => sierra3_ditherer(),
    };

    let palette_f64: Vec<[f64; 3]> = palette
        .into_iter()
        .map(|(r, g, b)| [f64::from(r), f64::from(g), f64::from(b)])
        .collect();

    let quantize = move |pixel: RGBf64| {
        let mut min_dist = f64::MAX;
        let mut best_color = [0.0, 0.0, 0.0];

        for &color in &palette_f64 {
            let dist = (pixel.0[0] - color[0]).powi(2)
                + (pixel.0[1] - color[1]).powi(2)
                + (pixel.0[2] - color[2]).powi(2);

            if dist < min_dist {
                min_dist = dist;
                best_color = color;
            }
        }
        let best_rgb = RGBf64(best_color);
        let error = pixel - best_rgb;
        (best_rgb, error)
    };

    let pixels: Vec<[u8; 3]> = image
        .to_rgb8()
        .into_raw()
        .chunks_exact(3)
        .map(|chunk| [chunk[0], chunk[1], chunk[2]])
        .collect();

    let img = Img::<[u8; 3]>::new(pixels, image.width())
        .unwrap()
        .convert_with(|pixel| {
            RGBf64([
                f64::from(pixel[0]),
                f64::from(pixel[1]),
                f64::from(pixel[2]),
            ])
        });

    let dithered = ditherer.dither(img, quantize);
    let w = dithered.width();
    let h = dithered.height();
    let dithered_u8 = dithered
        .convert_with(|pixel| {
            [
                clamp_f64_to_u8(pixel.0[0]),
                clamp_f64_to_u8(pixel.0[1]),
                clamp_f64_to_u8(pixel.0[2]),
            ]
        })
        .into_vec();

    let flat_vec: Vec<u8> = dithered_u8.into_iter().flatten().collect();

    let result = RgbImage::from_raw(w, h, flat_vec).unwrap();
    DynamicImage::ImageRgb8(result)
}
