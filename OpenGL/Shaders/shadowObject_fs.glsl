#version 330 core
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec3 Normal;
    vec2 TexCoords;
    vec4 FragPosLightSpace;
} fs_in;

uniform sampler2D floorTexture;
uniform sampler2D shadowMap;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform bool blinn;

float ShadowCalculation(vec4 FragPosLightSpace)
{
    vec3 projCoords = FragPosLightSpace.xyz / FragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;

    // 解决阴影偏移
    vec3 normal = normalize(fs_in.Normal);
    vec3 light_dir = normalize(lightPos - fs_in.FragPos);
    float bias = max(0.05 * (1.0 - dot(normal, light_dir)), 0.005);

    // PCF 多次采样取平均
    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    for(int x = -1; x <= 1; ++x){
        for(int y = -1; y <= 1; ++y){
            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x,y) * texelSize).r;
            shadow += projCoords.z - bias > pcfDepth ? 1.0 : 0.0;
        }
    }
    shadow /= 9.0;

    if(projCoords.z > 1.0)
        shadow = 0.0;
    return shadow;
}

void main()
{     
    vec3 color = texture(floorTexture, fs_in.TexCoords).rgb;
    vec3 normal = normalize(fs_in.Normal);
    vec3 lightColor = vec3(1.0);
    
    // ambient
    vec3 ambient = 0.15 * color;

    // diffuse
    vec3 light_dir = normalize(lightPos - fs_in.FragPos);
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
    vec3 specular = spec * lightColor; 

    // 计算阴影
    float shadow = ShadowCalculation(fs_in.FragPosLightSpace);
    vec3 lighting = (ambient + (1.0 - shadow) * (diffuse + specular)) * color;

    FragColor = vec4(lighting, 1.0);   
}

