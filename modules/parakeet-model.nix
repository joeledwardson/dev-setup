# INT8 Parakeet v3 files for hyprwhspr-rs. Pinned separately so the model can
# be built and tested without building a NixOS system.
{ fetchurl, runCommand }:
let
  revision = "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce";
  modelUrl = name: "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/${revision}/${name}";
  encoder = fetchurl {
    url = modelUrl "encoder-model.int8.onnx";
    hash = "sha256-YTnS+n4bCGCXsnfHFJcl7bq4nMfHrmSyPHQb5AVa/wk=";
  };
  decoder = fetchurl {
    url = modelUrl "decoder_joint-model.int8.onnx";
    hash = "sha256-7qdIPuPRowN12u3I7YPjlgyRsJiBISeg2Z0ciXdmenA=";
  };
  vocab = fetchurl {
    url = modelUrl "vocab.txt";
    hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
  };
in
runCommand "parakeet-tdt-0.6b-v3-int8" { } ''
  mkdir -p "$out"
  # The loader accepts INT8, but hyprwhspr-rs's startup check only recognises
  # the FP32 names. Both links target the INT8 files; no FP32 weights are used.
  ln -s ${encoder} "$out/encoder-model.onnx"
  ln -s ${decoder} "$out/decoder_joint-model.onnx"
  ln -s ${vocab} "$out/vocab.txt"
''
