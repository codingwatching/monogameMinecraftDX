﻿using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using monogameMinecraftShared.Utility;

namespace monogameMinecraftShared.Rendering
{
    public class MotionBlurRenderer : FullScreenQuadRenderer, IPostProcessor
    {
        public GraphicsDevice device;
        public Effect motionBlurEffect;
        public MotionVectorRenderer motionVectorRenderer;
        public RenderTarget2D processedImage { get; set; }

        public MotionBlurRenderer(GraphicsDevice device, Effect motionBlurEffect, MotionVectorRenderer motionVectorRenderer)
        {
            this.device = device;
            this.motionBlurEffect = motionBlurEffect;
            this.motionVectorRenderer = motionVectorRenderer;
            InitializeVertices();
            InitializeQuadBuffers(device);
            int width = device.PresentationParameters.BackBufferWidth;
            int height = device.PresentationParameters.BackBufferHeight;
            processedImage = new RenderTarget2D(device, width, height, false, SurfaceFormat.Color, DepthFormat.Depth24);
        }

        public void ProcessImage(in RenderTarget2D tex)
        {
            if (GameOptions.renderMotionBlur == false)
            {
                processedImage = tex;
                return;
            }
            motionBlurEffect.Parameters["MotionVectorTex"]?.SetValue(motionVectorRenderer.renderTargetMotionVector);
            motionBlurEffect.Parameters["InputTexture"]?.SetValue(tex);
            motionBlurEffect.Parameters["PixelSize"]?.SetValue(new Vector2(1f / tex.Width, 1f / tex.Height));
            RenderQuad(device, processedImage, motionBlurEffect, false, false, false);
            //        return renderTargetMotionBlur;  
        }
    }
}
