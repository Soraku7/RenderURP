using UnityEngine;
using UnityEngine.Rendering.Universal;

public class RimLightController : MonoBehaviour
{
    public Color rimColor = Color.cyan;
    public float rimPower = 4f;
    public float rimIntensity = 1f;

    private Renderer _renderer;
    private MaterialPropertyBlock _mpb;

    void Start()
    {
        _renderer = GetComponent<Renderer>();
        _mpb = new MaterialPropertyBlock();

        _renderer.GetPropertyBlock(_mpb);
        _mpb.SetColor("_RimColor", rimColor);
        _mpb.SetFloat("_RimPower", rimPower);
        _mpb.SetFloat("_RimIntensity", rimIntensity);
        _renderer.SetPropertyBlock(_mpb);
    }
    
}


