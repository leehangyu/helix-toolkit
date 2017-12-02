﻿// --------------------------------------------------------------------------------------------------------------------
// <copyright file="PatchGeometryModel3D.cs" company="Helix Toolkit">
//   Copyright (c) 2014 Helix Toolkit contributors
// </copyright>
// <summary>
//
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace HelixToolkit.Wpf.SharpDX
{
    using System.Windows;
    using Core;
    using System.Collections.Generic;
    using global::SharpDX.Direct3D;

    public static class TessellationTechniques
    {
#if TESSELLATION
        public enum Shading
        {
            Solid,
            Positions,
            Normals,
            TexCoords,
            Tangents,
            Colors
        };
        /// <summary>
        /// Passes available for this Model3D
        /// </summary>
        public static IEnumerable<string> Shadings { get { return new string[] { Shading.Solid.ToString(), Shading.Positions.ToString(), Shading.Normals.ToString(), Shading.TexCoords.ToString(), Shading.Tangents.ToString(), Shading.Colors.ToString() }; } }

#endif
    }

    public class PatchGeometryModel3D : MeshGeometryModel3D
    {
#if TESSELLATION
        #region Dependency Properties
        /// <summary>
        /// 
        /// </summary>
        public static readonly DependencyProperty ShadingProperty =
            DependencyProperty.Register("Shading", typeof(string), typeof(PatchGeometryModel3D), new AffectsRenderPropertyMetadata(TessellationTechniques.Shading.Solid.ToString(), (d,e)=> 
            {
                (((GeometryModel3D)d).RenderCore as PatchMeshRenderCore).TessellationTechniqueName = (string)e.NewValue;        
            }));

        /// <summary>
        /// 
        /// </summary>
        public static readonly DependencyProperty TessellationFactorProperty =
            DependencyProperty.Register("TessellationFactor", typeof(double), typeof(PatchGeometryModel3D), new AffectsRenderPropertyMetadata(1.0, (d,e)=> 
            {
                (((GeometryModel3D)d).RenderCore as PatchMeshRenderCore).TessellationFactor = (float)(double)e.NewValue;
            }));


        /// <summary>
        /// 
        /// </summary>
        public string Shading
        {
            get { return (string)GetValue(ShadingProperty); }
            set { SetValue(ShadingProperty, value); }
        }
        /// <summary>
        /// 
        /// </summary>
        public double TessellationFactor
        {
            get { return (double)GetValue(TessellationFactorProperty); }
            set { SetValue(TessellationFactorProperty, value); }
        }
        #endregion
       
        protected override IRenderCore OnCreateRenderCore()
        {
            return new PatchMeshRenderCore();
        }

        protected override void AssignDefaultValuesToCore(IRenderCore core)
        {
            (core as PatchMeshRenderCore).TessellationFactor = (float)TessellationFactor;
            (core as PatchMeshRenderCore).TessellationTechniqueName = this.Shading;
            base.AssignDefaultValuesToCore(core);
        }

        protected override RenderTechnique SetRenderTechnique(IRenderHost host)
        {
            return host.RenderTechniquesManager.RenderTechniques[TessellationRenderTechniqueNames.PNTriangles];
        }

        protected override bool CanHitTest(IRenderMatrices context)
        {
            if(BufferModel.Topology != PrimitiveTopology.PatchListWith3ControlPoints)
            {
                return false;
            }
            return base.CanHitTest(context);
        }
#endif
    }
}