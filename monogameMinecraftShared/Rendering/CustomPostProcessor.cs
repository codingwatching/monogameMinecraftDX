﻿using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
//using monogameMinecraftDX.Updateables;
using monogameMinecraftShared.Updateables;


namespace monogameMinecraftShared.Rendering
{
    public class CustomPostProcessor : FullScreenQuadRenderer, IPostProcessor
    {

        public Effect postProcessEffect;
        public GraphicsDevice device;
        public RenderTarget2D processedImage { get; set; }
        public MotionVectorRenderer motionVectorRenderer;
        public GBufferRenderer gBufferRenderer;
        bool isValid { get { return postProcessEffect != null; } }
        public string effectNameInDic = "";
        public Camera cam;
        public CustomPostProcessor(GraphicsDevice device, MotionVectorRenderer motionVectorRenderer, GBufferRenderer gBufferRenderer, string effectNameInDic)
        {
            this.device = device;
            int width = device.PresentationParameters.BackBufferWidth;
            int height = device.PresentationParameters.BackBufferHeight;
            processedImage = new RenderTarget2D(device, width, height, false, SurfaceFormat.Color, DepthFormat.Depth16);
            this.gBufferRenderer = gBufferRenderer;
            this.motionVectorRenderer = motionVectorRenderer;
            this.effectNameInDic = effectNameInDic;
        }
        public void LoadEffect(Effect effect)
        {
            postProcessEffect = effect;
        }
        public void ProcessImage(in RenderTarget2D rt)
        {
            if (isValid == false)
            {
                processedImage = rt;
                return;
            }
            SetCameraFrustum(cam, postProcessEffect);
            //   Debug.WriteLine(postProcessEffect.GraphicsDevice.ToString());
            postProcessEffect.Parameters["MotionVectorTex"]?.SetValue(motionVectorRenderer.renderTargetMotionVector);
            postProcessEffect.Parameters["InputTexture"]?.SetValue(rt);
            postProcessEffect.Parameters["PixelSize"]?.SetValue(new Vector2(1f / rt.Width, 1f / rt.Height));
            postProcessEffect.Parameters["ProjectionDepthTex"]?.SetValue(gBufferRenderer.renderTargetProjectionDepth);
            postProcessEffect.Parameters["NormalTex"]?.SetValue(gBufferRenderer.renderTargetNormalWS);
            RenderQuad(device, processedImage, postProcessEffect, false, false, false);
        }
    }
}
