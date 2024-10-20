﻿using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using monogameMinecraftShared.Asset;
using monogameMinecraftShared.Rendering.Particle;
using monogameMinecraftShared.Updateables;
using monogameMinecraftShared.Utility;
using monogameMinecraftShared.World;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace monogameMinecraftShared.Rendering
{
    public class LowDefRenderPipelineManager : IRenderPipelineManager
    {
        public MinecraftGameBase game { get; set ; }
        public IEffectsManager effectsManager { get ; set; }
        public WalkablePathVisualizationRenderer walkablePathVisualizationRenderer { get; set; }
        public BoundingBoxVisualizationRenderer boundingBoxVisualizationRenderer { get; set ; }
        public ChunkRenderer chunkRenderer { get; set; }
        public ParticleRenderer particleRenderer { get ; set; }
        public Texture2D environmentHDRITex;
        public Texture2D environmentHDRITexNight;

        public SkyboxRenderer skyboxRenderer;
        public GBufferRenderer gBufferRenderer;
        public List<IEntityRenderer> entityRenderers { get; set; }
        public List<IPostRenderingRenderer> postRenderingRenderers { get; set; }
        public TerrainMipmapGenerator terrainMipmapGenerator;
        public HDRCubemapRendererLowDef hdrCubemapRenderer;
        public DeferredShadingRendererLowDef deferredShadingRendererLowDef;
        public SSAORenderer ssaoRenderer;

        public IVoxelWorldWithRenderingChunkBuffers curRenderingWorld { get; set; }
        public LowDefRenderPipelineManager(MinecraftGameBase game, IEffectsManager em,Action optionalPostInitRenderPipelineAction=null)
        {
            this.game = game;
            effectsManager = em;
            this.optionalPostInitRenderPipelineAction= optionalPostInitRenderPipelineAction;
        }
        public Action optionalPostInitRenderPipelineAction { get; set; }
        public Action<IRenderPipelineManager> optionalPostRenderingAction { get; set; }
        public void InitRenderPipeline(Action<IRenderPipelineManager> postRenderingAction = null)
        {
            entityRenderers = new List<IEntityRenderer>();
            postRenderingRenderers = new List<IPostRenderingRenderer>();
            if (game.gameArchitecturePatternType == GameArchitecturePatternType.Local)
            {
                curRenderingWorld = VoxelWorld.currentWorld;
            }
            environmentHDRITex = game.Content.Load<Texture2D>("environmenthdri");
            environmentHDRITexNight = game.Content.Load<Texture2D>("environmenthdrinight");
            terrainMipmapGenerator = new TerrainMipmapGenerator(game.GraphicsDevice, effectsManager.gameEffects["texturecopyeffect"]);
       /*     brdfLUTRenderer = new BRDFLUTRenderer(game.GraphicsDevice, effectsManager.gameEffects["brdfluteffect"]);
            brdfLUTRenderer.CalculateLUT();*/
            hdrCubemapRenderer = new HDRCubemapRendererLowDef(game.GraphicsDevice, effectsManager.gameEffects["hdricubeeffect"], environmentHDRITex, environmentHDRITexNight);
            hdrCubemapRenderer.Render(hdrCubemapRenderer.resultCubeCollection, 0);
            hdrCubemapRenderer.Render(hdrCubemapRenderer.resultCubeCollectionNight, 1);

            chunkRenderer = new ChunkRenderer(game, game.GraphicsDevice,null, null, game.gameTimeManager);

            //    chunkRenderer.SetTexture(terrainTexNoMip, terrainNormal, terrainDepth, terrainTexNoMip, terrainMER);

            //     BlockResourcesManager.LoadDefaultResources(game.Content, game.GraphicsDevice, chunkRenderer);
            /* gBufferEffect = game.Content.Load<Effect>("gbuffereffect");
             gBufferEntityEffect = game.Content.Load<Effect>("gbufferentityeffect");*/
            chunkRenderer.SetTexture(BlockResourcesManager.instance.atlasNormal, null, BlockResourcesManager.instance.atlas, BlockResourcesManager.instance.atlasMER);

            particleRenderer = new ParticleRenderer(game.GraphicsDevice,
                effectsManager.gameEffects["gbufferparticleeffect"], game.gamePlayerR.gamePlayer, true);
            particleRenderer.SetTexture(BlockResourcesManager.instance.particleAtlas, BlockResourcesManager.instance.particleAtlasNormal, BlockResourcesManager.instance.particleAtlasMER);
            //       BlockResourcesManager.LoadDefaultParticleResources(game.Content, game.GraphicsDevice, particleRenderer);
            if (game.gameArchitecturePatternType == GameArchitecturePatternType.Local)
            {
                entityRenderers.Add(new EntityRenderer(game.GraphicsDevice, game.gamePlayerR.gamePlayer, null, null, game.gameTimeManager, effectsManager.gameEffects["gbufferentityeffect"]));
            }
          
            gBufferRenderer = new GBufferRenderer(game.GraphicsDevice, effectsManager.gameEffects["gbuffereffect"], effectsManager.gameEffects["gbufferentityeffect"], effectsManager.gameEffects["gbufferdepthpeelingeffect"], game.gamePlayerR.gamePlayer, chunkRenderer, entityRenderers.Count>0? entityRenderers[0]:null, particleRenderer);
            skyboxRenderer = new SkyboxRenderer(game.GraphicsDevice, effectsManager.gameEffects["skyboxeffect"], null, game.gamePlayerR.gamePlayer, game.Content.Load<Texture2D>("skybox/skybox"), game.Content.Load<Texture2D>("skybox/skyboxup"), game.Content.Load<Texture2D>("skybox/skybox"), game.Content.Load<Texture2D>("skybox/skybox"), game.Content.Load<Texture2D>("skybox/skyboxdown"), game.Content.Load<Texture2D>("skybox/skybox"),
               game.Content.Load<Texture2D>("skybox/skyboxnight"), game.Content.Load<Texture2D>("skybox/skyboxnightup"), game.Content.Load<Texture2D>("skybox/skyboxnight"), game.Content.Load<Texture2D>("skybox/skyboxnight"), game.Content.Load<Texture2D>("skybox/skyboxnightdown"), game.Content.Load<Texture2D>("skybox/skyboxnight"), game.gameTimeManager
               );
            skyboxRenderer.skyboxTexture = hdrCubemapRenderer.resultCubeCollection;
            skyboxRenderer.skyboxTextureNight = hdrCubemapRenderer.resultCubeCollectionNight;
            ssaoRenderer = new SSAORenderer(effectsManager.gameEffects["ssaoeffect"], gBufferRenderer, chunkRenderer, game.GraphicsDevice, game.gamePlayerR.gamePlayer, game.Content.Load<Texture2D>("randomnormal"));
            /*        contactShadowRenderer = new ContactShadowRenderer(game.GraphicsDevice, effectsManager.gameEffects["contactshadoweffect"], gBufferRenderer, game.gameTimeManager, game.gamePlayer);
                    shadowRenderer = new ShadowRenderer(game, game.GraphicsDevice, effectsManager.gameEffects["createshadowmapeffect"], chunkRenderer, entityRenderer, game.gameTimeManager);
                    motionVectorRenderer = new MotionVectorRenderer(game.GraphicsDevice, effectsManager.gameEffects["motionvectoreffect"], gBufferRenderer, game.gamePlayer);
                    ssaoRenderer = new SSAORenderer(effectsManager.gameEffects["ssaoeffect"], gBufferRenderer, chunkRenderer, game.GraphicsDevice, game.gamePlayer, game.Content.Load<Texture2D>("randomnormal"));
                    fxaaRenderer = new FXAARenderer(game.GraphicsDevice, effectsManager.gameEffects["fxaaeffect"]);
                    motionBlurRenderer = new MotionBlurRenderer(game.GraphicsDevice, effectsManager.gameEffects["motionblureffect"], motionVectorRenderer);*/
            deferredShadingRendererLowDef = new DeferredShadingRendererLowDef(game.GraphicsDevice, effectsManager.gameEffects["deferredblockeffect"],ssaoRenderer, game.gameTimeManager, gBufferRenderer, skyboxRenderer);


     /*       customPostProcessors.Add(new CustomPostProcessor(game.GraphicsDevice, motionVectorRenderer, gBufferRenderer, "postprocess0"));
            customPostProcessors.Add(new CustomPostProcessor(game.GraphicsDevice, motionVectorRenderer, gBufferRenderer, "postprocess1"));
            customPostProcessors.Add(new CustomPostProcessor(game.GraphicsDevice, motionVectorRenderer, gBufferRenderer, "postprocess2"));
            customPostProcessors.Add(new CustomPostProcessor(game.GraphicsDevice, motionVectorRenderer, gBufferRenderer, "postprocess3"));
            effectsManager.LoadCustomPostProcessEffects(game.GraphicsDevice, customPostProcessors, game.Content);
            hiZBufferRenderer = new HiZBufferRenderer(game.GraphicsDevice, effectsManager.gameEffects["hizbuffereffect"], gBufferRenderer, effectsManager.gameEffects["texturecopyraweffect"]);
            ssrRenderer = new SSRRenderer(game.GraphicsDevice, game.gamePlayer, gBufferRenderer, effectsManager.gameEffects["ssreffect"], deferredShadingRenderer, effectsManager.gameEffects["texturecopyraweffect"], motionVectorRenderer, hiZBufferRenderer, hdrCubemapRenderer, game.gameTimeManager);
            ssidRenderer = new SSIDRenderer(game.GraphicsDevice, effectsManager.gameEffects["ssideffect"], gBufferRenderer, game.gamePlayer, deferredShadingRenderer, effectsManager.gameEffects["texturecopyraweffect"], motionVectorRenderer, hiZBufferRenderer, hdrCubemapRenderer, game.gameTimeManager);

            deferredShadingRenderer.customPostProcessors = customPostProcessors;
            deferredShadingRenderer.ssidRenderer = ssidRenderer;
            deferredShadingRenderer.ssrRenderer = ssrRenderer;
            chunkRenderer.shadowRenderer = shadowRenderer;
            chunkRenderer.SSAORenderer = ssaoRenderer;
            entityRenderer.shadowRenderer = shadowRenderer;
            chunkRenderer.lightUpdater = pointLightUpdater;
            shadowRenderer.zombieModel = game.Content.Load<Model>("zombiemodelref");

            volumetricLightRenderer = new VolumetricLightRenderer(game.GraphicsDevice, gBufferRenderer, game._spriteBatch, effectsManager.gameEffects["volumetricmaskblendeffect"], effectsManager.gameEffects["lightshafteffect"], game.gamePlayer, game.gameTimeManager);
            chunkRenderer.SSRRenderer = ssrRenderer;
            volumetricLightRenderer.entityRenderer = entityRenderer;*/
            boundingBoxVisualizationRenderer = new BoundingBoxVisualizationRenderer();
            boundingBoxVisualizationRenderer.Initialize(environmentHDRITex, game.GraphicsDevice, effectsManager.gameEffects["debuglineeffect"], gBufferRenderer);
            walkablePathVisualizationRenderer = new WalkablePathVisualizationRenderer();
            walkablePathVisualizationRenderer.Initialize(environmentHDRITex, game.GraphicsDevice, effectsManager.gameEffects["debuglineeffect"], gBufferRenderer);
            if (optionalPostInitRenderPipelineAction != null)
            {
                optionalPostInitRenderPipelineAction();
            }
            this.optionalPostRenderingAction = optionalPostRenderingAction;
        }

        public void RenderWorld(GameTime gameTime, SpriteBatch sb)
        {
            if (game.gameArchitecturePatternType == GameArchitecturePatternType.Local)
            {
                curRenderingWorld = VoxelWorld.currentWorld;
            }
            if (curRenderingWorld == null)
            {
                return;
            }
            game.GraphicsDevice.DepthStencilState = DepthStencilState.Default;

            //  GraphicsDevice.RasterizerState = rasterizerState;
            game.GraphicsDevice.BlendState = BlendState.Opaque;
            gBufferRenderer.Draw(curRenderingWorld.renderingChunks);
            ssaoRenderer.Draw();
        
            deferredShadingRendererLowDef.Draw(game.gamePlayerR.gamePlayer,game._spriteBatch);
          
            game.GraphicsDevice.DepthStencilState = DepthStencilState.None;
            game.GraphicsDevice.BlendState = BlendState.Additive;


            if (curRenderingWorld is VoxelWorld)
            {
                if (game.gamePlayerR.gamePlayer is GamePlayer gamePlayer1)
                {
                    if (VoxelWorld.currentWorld.structureOperationsManager != null)
                    {
                        VoxelWorld.currentWorld.structureOperationsManager.DrawStructureSavingBounds(gamePlayer1, this);
                        VoxelWorld.currentWorld.structureOperationsManager.DrawStructurePlacingBounds(gamePlayer1, this);
                    }

                    if (gamePlayer1.curChunk != null)
                    {
                        EntityManager.pathfindingManager.DrawDebuggingPath(new Vector3(0, 0, 0), gamePlayer1, this);

                    }
                }
            }


            foreach (var item in postRenderingRenderers)
            {
                item.DrawPostRendering();
            }

        }

        public void Resize()
        {
            int width = game.GraphicsDevice.PresentationParameters.BackBufferWidth;
            int height = game.GraphicsDevice.PresentationParameters.BackBufferHeight;
            Debug.WriteLine(width);
            Debug.WriteLine(height);
            gBufferRenderer.Resize(width, height, game.GraphicsDevice);



            ssaoRenderer.ssaoTarget = new RenderTarget2D(ssaoRenderer.graphicsDevice, width / 2, height / 2, false, SurfaceFormat.Color, DepthFormat.Depth24);
         
           
            deferredShadingRendererLowDef.finalImage = new RenderTarget2D(game.GraphicsDevice, width, height, false, SurfaceFormat.Color, DepthFormat.Depth24);
          
            float aspectRatio = game.GraphicsDevice.Viewport.Width / (float)game.GraphicsDevice.Viewport.Height;
            game.gamePlayerR.gamePlayer.cam.aspectRatio = aspectRatio;
            game.gamePlayerR.gamePlayer.cam.projectionMatrix = Matrix.CreatePerspectiveFieldOfView(MathHelper.ToRadians(90), aspectRatio, 0.1f, 1000f);
        }
    }
}
