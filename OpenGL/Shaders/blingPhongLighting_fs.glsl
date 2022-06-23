#version 330 core
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec3 Normal;
    vec2 TexCoords;
} fs_in;

uniform sampler2D floorTexture;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform bool blinn;

void main()
{     
    vec3 color = texture(floorTexture, fs_in.TexCoords).rgb;

    // ambient
    vec3 ambient = 0.05 * color;

    // diffuse
    vec3 light_dir = normalize(lightPos - fs_in.FragPos);
    vec3 normal = normalize(fs_in.Normal);
    float diff = max(dot(light_dir, normal), 0.0);
    vec3 diffuse = diff * color;

    // specular
    float spec = 0.0;
    vec3 view_dir = normalize(viewPos - fs_in.FragPos);
    if(blinn){
        vec3 half_dir = normalize(light_dir + view_dir);
        spec = pow(max(0.0, dot(half_dir, normal)), 32.0);
    }else{
        vec3 reflect_dir = normalize(reflect(-light_dir, normal));
        spec = pow(max(0.0, dot(reflect_dir, view_dir)), 8.0);
    }
    vec3 specular = spec * vec3(0.3); // 镜面反射没有颜色

    FragColor = vec4(ambient + diffuse + specular, 1.0);   
}

