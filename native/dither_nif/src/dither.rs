use dither_lib::{
    clamp_f64_to_u8, create_quantize_n_bits_func,
    ditherer::{
        atkinson_ditherer, burkes_ditherer, floyd_steinberg_ditherer, jarvis_ditherer,
        sierra3_ditherer, stucki_ditherer, Dither,
    },
    img::Img,
};
use image::{DynamicImage, GrayImage};

use crate::types::DitherAlgorithm;

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
