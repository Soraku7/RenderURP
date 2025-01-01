using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public class BoxBlur : MonoBehaviour
{
    public Material material;
    [Range(0, 10)]
    public int _Iteration = 4;
    [Range(1, 10)]
    public float _DownSample = 2.0f;

    [System.Obsolete]
    void Start()
    {
        if (material == null || SystemInfo.supportsImageEffects == false
            || material.shader == null || material.shader.isSupported == false)
        {
            enabled = false;
            return;
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //获得画布宽高
        int width = (int)(source.width / _DownSample);
        int height = (int)(source.height / _DownSample);
        //创建多个画布
        RenderTexture RT1 = RenderTexture.GetTemporary(width, height);
        RenderTexture RT2 = RenderTexture.GetTemporary(width, height);

        Graphics.Blit(source, RT1);

        for (int i = 0; i < _Iteration; i++)
        {
            Graphics.Blit(RT1, RT2, material, 0);
            Graphics.Blit(RT2, RT1, material, 0);
        }

        Graphics.Blit(RT1, destination);

        //release
        RenderTexture.ReleaseTemporary(RT1);
        RenderTexture.ReleaseTemporary(RT2);
    }
}