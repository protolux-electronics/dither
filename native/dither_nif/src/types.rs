use image::DynamicImage;
use rustler::{Resource, ResourceArc};
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

    // errors
    invalid_buffer
}

pub struct ImageResource {
    pub inner: Mutex<DynamicImage>,
}

#[rustler::resource_impl]
impl Resource for ImageResource {}

pub type ImageArc = ResourceArc<ImageResource>;

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
}

impl<'a> rustler::Decoder<'a> for DitherType {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        let atom: rustler::Atom = term.decode()?;
        match atom {
            x if x == bw() => Ok(DitherType::BlackAndWhite),
            _ => Err(rustler::Error::BadArg),
        }
    }
}
