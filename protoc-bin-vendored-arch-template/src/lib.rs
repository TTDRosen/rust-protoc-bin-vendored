use std::path::PathBuf;
use std::path::Path;

/// Return a path to `protoc` binary for @@ARCH@@.
pub fn protoc_bin_path() -> PathBuf {
    let protoc_bin_path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("bin")
        .join("protoc@@EXE_SUFFIX@@");
    assert!(
        protoc_bin_path.exists(),
        "internal: protoc not found {}",
        protoc_bin_path.display(),
    );
    protoc_bin_path
}

#[cfg(test)]
mod test {
    use crate::protoc_bin_path;

    #[test]
    fn smoke() {
        assert!(protoc_bin_path().exists());
    }
}
