﻿using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace monogameMinecraftDX.Rendering
{
    public class FXAARenderer : FullScreenQuadRenderer
    {
        public GraphicsDevice device;
        public Effect fxaaEffect;
        public RenderTarget2D renderTargetProcessed;
        public FXAARenderer(GraphicsDevice device, Effect fxaaEffect)
        {
            this.device = device;
            this.fxaaEffect = fxaaEffect;

            int width = device.PresentationParameters.BackBufferWidth;
            int height = device.PresentationParameters.BackBufferHeight;


            renderTargetProcessed = new RenderTarget2D(device, width, height, false, SurfaceFormat.Color, DepthFormat.Depth24);
            InitializeVertices();
            InitializeQuadBuffers(device);
        }

        public void Draw(bool isFinalProcess, RenderTarget2D inputImage)
        {

            int width = device.PresentationParameters.BackBufferWidth;
            int height = device.PresentationParameters.BackBufferHeight;
            fxaaEffect.Parameters["InputTexture"].SetValue(inputImage);
            Vector2 pixelSize = new Vector2(1f / width, 1f / height);

            fxaaEffect.Parameters["PixelSize"]?.SetValue(pixelSize);
            if (isFinalProcess)
            {
                RenderQuad(device, null, fxaaEffect, false, true, false);
            }
            else
            {
                RenderQuad(device, renderTargetProcessed, fxaaEffect);
            }

        }
    }
}
