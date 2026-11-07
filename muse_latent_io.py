"""
Muse Latent IO - salva/carica latenti ComfyUI completi, anche NestedTensor
(video + audio insieme) e con tutti i dati extra che il Muse Director allega
(chunk bundle, keyframe, seed...). Il SaveLatent standard di ComfyUI non lo supporta.

Installazione: copia questo file in ComfyUI/custom_nodes/ e riavvia ComfyUI.
I file vengono salvati in ComfyUI/output/muse_latents/ (.pt).
Sono file tuoi: vengono letti con torch.load(weights_only=False).
"""
import os
import pickle
import re
import shutil

import torch
import folder_paths

SUBDIR = "muse_latents"


def _dir():
    d = os.path.join(folder_paths.get_output_directory(), SUBDIR)
    os.makedirs(d, exist_ok=True)
    return d


def _to_cpu(v):
    """Copia ricorsiva con tutti i tensori spostati su CPU; il resto resta com'e'."""
    if isinstance(v, torch.Tensor):
        return v.detach().cpu().contiguous()
    if hasattr(v, "tensors") and not isinstance(v, (dict, list, tuple)):  # NestedTensor
        try:
            return type(v)(tuple(_to_cpu(t) for t in v.tensors))
        except Exception:
            return v
    if isinstance(v, dict):
        return {k: _to_cpu(x) for k, x in v.items()}
    if isinstance(v, list):
        return [_to_cpu(x) for x in v]
    if isinstance(v, tuple):
        return tuple(_to_cpu(x) for x in v)
    return v


def _describe(v):
    if isinstance(v, torch.Tensor):
        return f"Tensor{tuple(v.shape)}"
    if hasattr(v, "tensors") and not isinstance(v, (dict, list, tuple)):
        return f"Nested[{len(v.tensors)}]"
    if isinstance(v, dict):
        return f"dict[{len(v)}]"
    if isinstance(v, (list, tuple)):
        return f"{type(v).__name__}[{len(v)}]"
    return type(v).__name__


class MuseSaveLatentNested:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "samples": ("LATENT",),
                "filename_prefix": ("STRING", {"default": "Muse_cand1"}),
            }
        }

    RETURN_TYPES = ()
    FUNCTION = "save"
    OUTPUT_NODE = True
    CATEGORY = "Muse"

    def save(self, samples, filename_prefix):
        d = _dir()
        prefix = re.sub(r"[^A-Za-z0-9_.-]", "_", filename_prefix) or "latent"
        name = f"{prefix}.pt"  # nome fisso: ogni nuova generazione sovrascrive la precedente
        full = os.path.abspath(os.path.join(d, name))

        payload = {}
        for k, v in samples.items():
            cv = _to_cpu(v)
            try:
                pickle.dumps(cv)  # controlla che si possa serializzare
                payload[k] = cv
            except Exception as e:
                print(f"[MuseSaveLatentNested] ATTENZIONE: chiave '{k}' ({_describe(v)}) non salvabile: {e}")
        # Il Refine legge i chunk del candidato da una cartella su disco (_muse_scout_bundle["dir"]),
        # che puo' sparire (cartella temp, riavvio, nuova generazione). La copio accanto al .pt
        # e punto il bundle salvato alla copia.
        bundle = samples.get("_muse_scout_bundle")
        if isinstance(bundle, dict) and bundle.get("dir") and os.path.isdir(bundle["dir"]):
            src = os.path.abspath(bundle["dir"])
            dst = os.path.abspath(os.path.join(d, f"{prefix}_bundle"))
            if src != dst:
                if os.path.isdir(dst):
                    shutil.rmtree(dst)
                shutil.copytree(src, dst)
            nb = dict(bundle)
            nb["dir"] = dst
            payload["_muse_scout_bundle"] = nb
            print(f"[MuseSaveLatentNested] bundle copiato in: {dst}")
        torch.save(payload, full)
        size_mb = os.path.getsize(full) / (1024 * 1024)
        print(f"[MuseSaveLatentNested] salvato: {full} ({size_mb:.1f} MB)")
        print("[MuseSaveLatentNested] chiavi: " + ", ".join(f"{k}={_describe(v)}" for k, v in payload.items()))
        return {}


class MuseLoadLatentNested:
    @classmethod
    def INPUT_TYPES(cls):
        files = sorted(f for f in os.listdir(_dir()) if f.endswith(".pt"))
        return {"required": {"latent_file": (files if files else [""],)}}

    RETURN_TYPES = ("LATENT",)
    FUNCTION = "load"
    CATEGORY = "Muse"

    @classmethod
    def IS_CHANGED(cls, latent_file):
        p = os.path.join(_dir(), latent_file)
        return os.path.getmtime(p) if os.path.exists(p) else ""

    @classmethod
    def VALIDATE_INPUTS(cls, latent_file):
        if not latent_file or not os.path.exists(os.path.join(_dir(), latent_file)):
            return f"File latente non trovato in output/{SUBDIR}: {latent_file}"
        return True

    def load(self, latent_file):
        out = torch.load(os.path.join(_dir(), latent_file), map_location="cpu", weights_only=False)
        print("[MuseLoadLatentNested] caricato " + latent_file + " | chiavi: "
              + ", ".join(f"{k}={_describe(v)}" for k, v in out.items()))
        return (out,)


NODE_CLASS_MAPPINGS = {
    "MuseSaveLatentNested": MuseSaveLatentNested,
    "MuseLoadLatentNested": MuseLoadLatentNested,
}
NODE_DISPLAY_NAME_MAPPINGS = {
    "MuseSaveLatentNested": "Muse Save Latent (nested ok)",
    "MuseLoadLatentNested": "Muse Load Latent (nested ok)",
}
