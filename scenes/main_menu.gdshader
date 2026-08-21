shader_type canvas_item;

// Paramètres que tu pourras régler dans l'inspecteur
uniform float darkness_threshold : hint_range(0.0, 1.0) = 0.1; // Tout ce qui est plus sombre que ça sera modifié
uniform vec4 replacement_color : source_color = vec4(1.0); // La couleur de remplacement (blanc par défaut)

void fragment() {
    // Récupère la couleur du pixel original
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calcule la "luminosité" (luminance) de la couleur
    // Les couleurs sombres ont une faible valeur, les couleurs claires une valeur élevée
    float luminance = dot(tex_color.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Si le pixel est opaque (partie du logo) ET plus sombre que le seuil défini...
    if (luminance < darkness_threshold && tex_color.a > 0.5) {
        // ...alors on remplace sa couleur par le blanc (ou la couleur choisie), en gardant sa transparence
        COLOR = vec4(replacement_color.rgb, tex_color.a);
    } else {
        // Sinon, on laisse le pixel tel quel (par exemple, les points colorés de heLdb resteront colorés)
        COLOR = tex_color;
    }
}
