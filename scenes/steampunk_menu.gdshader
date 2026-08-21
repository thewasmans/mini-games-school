shader_type canvas_item;

// Seuil de noirceur pour détecter le texte ou les pixels sombres
uniform float darkness_threshold : hint_range(0.0, 1.0) = 0.4;
// Couleur de remplacement (par défaut, du blanc pur)
uniform vec4 replacement_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calcule la luminosité moyenne du pixel
    float brightness = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
    
    // Si le pixel est sombre et non transparent, on le remplace
    if (brightness < darkness_threshold && tex_color.a > 0.05) {
        COLOR = vec4(replacement_color.rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}
