"""Extrait les éléments d'UI des maquettes (docs/*.jpg) en PNG séparés,
dans content/ui/. Ces PNG servent ensuite de thème à l'UI Godot (voir scripts/ui/ui_skin.gd).

    python addons/dev_tools/extract_ui_assets.py            # skins (boutons, panneaux, cases)
    python addons/dev_tools/extract_ui_assets.py --sprites  # + sprites détourés (nécessite `pip install rembg[cpu]`)

Trois techniques :
- Skins (boutons, panneaux) : découpe + effacement du texte par interpolation ligne par ligne
  entre deux colonnes propres + masque arrondi anticrénelé. Utilisés en 9-slice dans Godot.
- Variantes de couleur : « gradient map » de la luminance d'un skin propre vers une rampe de
  couleurs échantillonnée sur la maquette (vert, violet, jaune…).
- Sprites (icônes, plateformes, châteaux) : détourage automatique avec rembg.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "content", "ui")
_cache = {}


def src(name):
    if name not in _cache:
        _cache[name] = np.asarray(Image.open(os.path.join(ROOT, "docs", name + ".jpg")).convert("RGB")).astype(np.float32)
    return _cache[name]


def crop(name, box):
    x0, y0, x1, y1 = box
    return src(name)[y0:y1, x0:x1].copy()


def erase_rows(a, x0, x1, y0=0, y1=None, sample=3):
    """Efface le contenu entre les colonnes x0 et x1 en interpolant chaque ligne entre
    la moyenne des `sample` pixels juste à gauche de x0 et juste à droite de x1."""
    y1 = a.shape[0] if y1 is None else y1
    t = np.linspace(0.0, 1.0, x1 - x0)[None, :, None]
    left = a[y0:y1, x0 - sample:x0].mean(axis=1, keepdims=True)
    right = a[y0:y1, x1:x1 + sample].mean(axis=1, keepdims=True)
    a[y0:y1, x0:x1] = left * (1 - t) + right * t
    return a


def fill_rows_median(a, x0, x1, y0=0, y1=None, keep=10):
    """Remplace chaque ligne entre x0 et x1 par une couleur médiane calculée sur les `keep`
    colonnes les plus lisses verticalement (donc sans texte ni icône) : le texte disparaît
    et le dégradé vertical du bouton est conservé."""
    y1 = a.shape[0] if y1 is None else y1
    block = a[y0:y1, x0:x1]
    roughness = np.abs(np.diff(block, n=2, axis=0)).sum(axis=(0, 2))
    cleanest = np.argsort(roughness)[:keep]
    a[y0:y1, x0:x1] = np.median(block[:, cleanest], axis=1, keepdims=True)
    return a


def erase_cols(a, y0, y1, x0=0, x1=None, sample=3):
    """Même chose verticalement (interpolation entre la ligne au-dessus et celle en dessous)."""
    x1 = a.shape[1] if x1 is None else x1
    t = np.linspace(0.0, 1.0, y1 - y0)[:, None, None]
    top = a[y0 - sample:y0, x0:x1].mean(axis=0, keepdims=True)
    bottom = a[y1:y1 + sample, x0:x1].mean(axis=0, keepdims=True)
    a[y0:y1, x0:x1] = top * (1 - t) + bottom * t
    return a


def rounded_alpha(w, h, radius, inset=0.0, ss=4):
    """Masque de rectangle arrondi anticrénelé (suréchantillonné)."""
    m = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        (inset * ss, inset * ss, (w - inset) * ss - 1, (h - inset) * ss - 1), radius=radius * ss, fill=255)
    return np.asarray(m.resize((w, h), Image.LANCZOS)).astype(np.float32)


def to_png(a, alpha, name):
    rgba = np.dstack([np.clip(a, 0, 255), alpha]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, name + ".png"))
    print("  ", name + ".png", rgba.shape[1], "x", rgba.shape[0])
    return rgba


def luminance(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def gradient_map(rgba, ramp):
    """Recolore une image selon sa luminance (normalisée entre les centiles 2 et 98)
    vers une rampe [(position, (r, g, b)), …]."""
    a = rgba[..., :3].astype(np.float32)
    lum = luminance(a)
    visible = rgba[..., 3] > 128
    lo, hi = np.percentile(lum[visible], 2), np.percentile(lum[visible], 98)
    t = np.clip((lum - lo) / max(hi - lo, 1), 0, 1)
    pos = np.array([p for p, _ in ramp])
    cols = np.array([c for _, c in ramp], dtype=np.float32)
    out = np.stack([np.interp(t, pos, cols[:, k]) for k in range(3)], axis=-1)
    return np.dstack([out, rgba[..., 3]]).astype(np.uint8)


def save_rgba(rgba, name):
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, name + ".png"))
    print("  ", name + ".png", rgba.shape[1], "x", rgba.shape[0])


# --- Skins -------------------------------------------------------------------

def skins():
    print("Skins :")
    # Bouton / bannière bleue : bannière « MENU JOUER », propre aux deux extrémités.
    a = crop("menu-level-study", (121, 126, 727, 202))
    fill_rows_median(a, 30, a.shape[1] - 30, 3, a.shape[0] - 3)
    blue = to_png(a, rounded_alpha(a.shape[1], a.shape[0], 24, 0.5), "button_blue")

    # Bouton orange : « Hint » (ampoule et texte effacés).
    a = crop("crossword", (314, 860, 581, 951))
    fill_rows_median(a, 22, a.shape[1] - 22, 3, a.shape[0] - 3)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 26, 0.5), "button_orange")

    # Bouton PLAY (orange -> rose) : « Play Story Path ».
    a = crop("home-menu", (36, 319, 439, 429))
    fill_rows_median(a, 62, a.shape[1] - 26, 4, a.shape[0] - 4)  # garde la grande étincelle du coin
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 28, 0.5), "button_play")

    # Bouton « Retour » bleu nuit.
    a = crop("menu-level-study", (317, 1016, 531, 1083))
    fill_rows_median(a, 14, a.shape[1] - 14, 3, a.shape[0] - 3)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 20, 0.5), "button_navy")

    # Variantes de couleur par gradient map, rampes échantillonnées sur les maquettes.
    ramps = {
        "button_green": [(0, (18, 72, 24)), (0.35, (48, 150, 52)), (0.7, (98, 200, 80)), (1, (210, 255, 190))],
        "button_purple": [(0, (60, 20, 100)), (0.35, (128, 60, 190)), (0.7, (180, 105, 230)), (1, (240, 215, 255))],
        "button_yellow": [(0, (120, 72, 0)), (0.35, (235, 165, 10)), (0.7, (255, 210, 60)), (1, (255, 248, 200))],
        "button_red": [(0, (110, 15, 25)), (0.35, (215, 45, 60)), (0.7, (255, 105, 115)), (1, (255, 225, 225))],
        "button_grey": [(0, (55, 60, 75)), (0.35, (120, 128, 145)), (0.7, (165, 172, 188)), (1, (235, 238, 245))],
        "button_light": [(0, (140, 145, 185)), (0.35, (205, 210, 240)), (0.7, (236, 238, 255)), (1, (255, 255, 255))],
    }
    for name, ramp in ramps.items():
        save_rgba(gradient_map(blue, ramp), name)

    # Cadre titré (panneau « Clue ») : titre et texte effacés, intérieur bleu nuit conservé.
    a = crop("crossword", (25, 211, 211, 451))
    fill_rows_median(a, 20, a.shape[1] - 20, 4, 46)      # titre « Clue »
    erase_cols(a, 60, 214, 16, a.shape[1] - 16)          # texte de la liste (entre deux bandes propres)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 22, 0.5), "panel_titled")

    # Cadre de question (quiz) : texte et minuteur effacés.
    a = crop("quizz", (51, 149, 717, 331))
    fill_rows_median(a, 20, a.shape[1] - 18, 8, a.shape[0] - 12)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 30, 0.5), "panel_blue")

    # Grand conteneur bleu nuit à bord lumineux (menu des niveaux) : boutons effacés.
    a = crop("menu-level-study", (119, 229, 729, 969))
    erase_cols(a, 20, a.shape[0] - 28, 18, a.shape[1] - 18, sample=5)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 32, 0.5), "panel_container")

    # Cases du mot croisé
    a = crop("crossword", (164, 514, 210, 566))
    cell = to_png(a, rounded_alpha(a.shape[1], a.shape[0], 8, 0.5), "cell_empty")
    save_rgba(gradient_map(cell, [(0, (130, 55, 0)), (0.4, (240, 140, 25)), (0.8, (255, 195, 75)), (1, (255, 240, 190))]), "cell_done")
    save_rgba(gradient_map(cell, [(0, (150, 110, 0)), (0.4, (255, 205, 40)), (0.8, (255, 238, 140)), (1, (255, 255, 230))]), "cell_cursor")
    save_rgba(gradient_map(cell, [(0, (110, 15, 25)), (0.4, (225, 55, 70)), (0.8, (255, 125, 135)), (1, (255, 230, 230))]), "cell_wrong")
    save_rgba(gradient_map(cell, [(0, (20, 90, 35)), (0.4, (55, 170, 70)), (0.8, (130, 225, 120)), (1, (230, 255, 225))]), "cell_good")
    save_rgba(gradient_map(cell, [(0, (150, 140, 200)), (0.4, (225, 220, 250)), (0.8, (245, 243, 255)), (1, (255, 255, 255))]), "cell_word")

    # Touche du clavier (lettre effacée)
    a = crop("crossword", (620, 496, 652, 536))  # touche « i » (lettre fine)
    fill_rows_median(a, 6, a.shape[1] - 6, 4, a.shape[0] - 6)
    to_png(a, rounded_alpha(a.shape[1], a.shape[0], 8, 0.5), "key")

    # Boutons ronds de la barre du haut (gardés tels quels, icône comprise)
    for name, img, box in [("button_back", "home-menu", (37, 27, 109, 97)), ("button_gear", "home-menu", (740, 27, 811, 97)),
                           ("button_gear_orange", "menu-level-study", (740, 27, 811, 97))]:
        a = crop(img, box)
        to_png(a, rounded_alpha(a.shape[1], a.shape[0], 16, 0.5), name)


# --- Sprites détourés (rembg) ------------------------------------------------

SPRITES = {
    # nom: (image, boîte)
    "icon_book": ("menu-level-study", (196, 462, 300, 566)),
    "icon_pencil": ("menu-level-study", (560, 455, 650, 565)),
    "icon_ruler": ("menu-level-study", (560, 625, 650, 740)),
    "icon_scroll": ("menu-level-study", (195, 800, 300, 900)),
    "icon_microscope": ("menu-level-study", (560, 795, 650, 905)),
    "icon_castle": ("quizz", (268, 945, 350, 1035)),
    "icon_crown": ("quizz", (650, 1090, 732, 1170)),
    "icon_bulb": ("crossword", (340, 868, 420, 945)),
    "icon_coin": ("home-menu", (242, 30, 300, 88)),
    "icon_gem": ("home-menu", (444, 30, 506, 88)),
    "island_castle": ("quizz", (165, 375, 610, 900)),
    "platform_open": ("select-mini-game", (318, 425, 458, 548)),
    "platform_lock": ("select-mini-game", (490, 515, 626, 668)),
    "platform_stone": ("select-mini-game", (326, 735, 456, 880)),
    "castle_end": ("select-mini-game", (485, 125, 752, 445)),
    "castle_start": ("select-mini-game", (262, 930, 505, 1230)),
}


def sprites():
    from rembg import new_session, remove
    session = new_session("isnet-general-use")
    print("Sprites :")
    for name, (img, box) in SPRITES.items():
        a = crop(img, box).astype(np.uint8)
        cut = np.asarray(remove(Image.fromarray(a), session=session, post_process_mask=True))
        save_rgba(_trim(cut), name)
    # Compas : trop fin pour rembg, on retire le vert du bouton (chroma key).
    save_rgba(_trim(_chroma_key(crop("menu-level-study", (204, 624, 278, 744)).astype(np.uint8), 55, 125)), "icon_compass")
    # Plateforme terminée : le disque bleu de la plateforme ouverte passe au doré.
    open_ = np.asarray(Image.open(os.path.join(OUT, "platform_open.png")).convert("RGBA")).copy()
    save_rgba(_blue_to_gold(open_), "platform_done")


def _chroma_key(rgb, hue_min, hue_max):
    """Rend transparents les pixels saturés dont la teinte (échelle 0-255) est dans l'intervalle."""
    hsv = np.asarray(Image.fromarray(rgb).convert("HSV")).astype(np.float32)
    h, s = hsv[..., 0], hsv[..., 1]
    inside = (h >= hue_min) & (h <= hue_max)
    alpha = np.where(inside, np.clip((60 - s) * 6, 0, 255), 255).astype(np.uint8)
    alpha = np.asarray(Image.fromarray(alpha).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6)))
    return np.dstack([rgb, alpha]).astype(np.uint8)


def _trim(rgba, pad=2):
    ys, xs = np.nonzero(rgba[..., 3] > 8)
    if len(xs) == 0:
        return rgba
    y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, rgba.shape[0])
    x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad + 1, rgba.shape[1])
    return rgba[y0:y1, x0:x1]


def _blue_to_gold(rgba):
    img = Image.fromarray(rgba, "RGBA")
    hsv = np.asarray(img.convert("RGB").convert("HSV")).astype(np.int32)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    blue = (h > 120) & (h < 190) & (s > 60)   # teintes bleues/cyan (échelle 0-255)
    h = np.where(blue, 30, h)                  # ~42° : doré
    s = np.where(blue, np.minimum(s + 30, 255), s)
    rgb = np.asarray(Image.fromarray(np.dstack([h, s, v]).astype(np.uint8), "HSV").convert("RGB"))
    return np.dstack([rgb, rgba[..., 3]]).astype(np.uint8)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    skins()
    if "--sprites" in sys.argv:
        sprites()
