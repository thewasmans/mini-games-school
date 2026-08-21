shader_type canvas_item;

// Ajuste cette valeur pour rendre le flou plus ou moins fort (entre 0.0 et 5.0)
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec4 col = vec4(0.0);
    vec2 size = TEXTURE_PIXEL_SIZE * blur_amount;
    
    // Échantillonnage autour du pixel pour créer un vrai flou artistique
    col += texture(TEXTURE, UV + vec2(-size.x, -size.y));
    col += texture(TEXTURE, UV + vec2(0.0, -size.y));
    col += texture(TEXTURE, UV + vec2(size.x, -size.y));
    
    col += texture(TEXTURE, UV + vec2(-size.x, 0.0));
    col += texture(TEXTURE, UV + vec2(0.0, 0.0));
    col += texture(TEXTURE, UV + vec2(size.x, 0.0));
    
    col += texture(TEXTURE, UV + vec2(-size.x, size.y));
    col += texture(TEXTURE, UV + vec2(0.0, size.y));
    col += texture(TEXTURE, UV + vec2(size.x, size.y));
    
    COLOR = col / 9.0;
}