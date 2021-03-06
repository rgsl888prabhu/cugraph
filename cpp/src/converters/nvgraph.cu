/*
 * Copyright (c) 2019, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/** ---------------------------------------------------------------------------*
 * @brief Wrapper functions for Nvgraph
 *
 * @file nvgraph_gdf.cu
 * ---------------------------------------------------------------------------**/

#include <nvgraph_gdf.h>
#include <ctime>
#include "utilities/error_utils.h"
#include "converters/nvgraph.cuh"

gdf_error gdf_createGraph_nvgraph(nvgraphHandle_t nvg_handle,
                                  gdf_graph* gdf_G,
                                  nvgraphGraphDescr_t* nvg_G,
                                  bool use_transposed) {

  // check input
  GDF_REQUIRE(!((gdf_G->edgeList == nullptr) &&
                  (gdf_G->adjList == nullptr) &&
                  (gdf_G->transposedAdjList == nullptr)),
              GDF_INVALID_API_CALL);
  nvgraphTopologyType_t TT;
  cudaDataType_t settype;
  // create an nvgraph graph handle
  NVG_TRY(nvgraphCreateGraphDescr(nvg_handle, nvg_G));
  // setup nvgraph variables
  if (use_transposed) {
    // convert edgeList to transposedAdjList
    if (gdf_G->transposedAdjList == nullptr) {
      GDF_TRY(gdf_add_transposed_adj_list(gdf_G));
    }
    // using exiting transposedAdjList if it exisits and if adjList is missing
    TT = NVGRAPH_CSC_32;
    nvgraphCSCTopology32I_st topoData;
    topoData.nvertices = gdf_G->transposedAdjList->offsets->size - 1;
    topoData.nedges = gdf_G->transposedAdjList->indices->size;
    topoData.destination_offsets = (int *) gdf_G->transposedAdjList->offsets->data;
    topoData.source_indices = (int *) gdf_G->transposedAdjList->indices->data;
    // attach the transposed adj list
    NVG_TRY(nvgraphAttachGraphStructure(nvg_handle, *nvg_G, (void * )&topoData, TT));
    //attach edge values
    if (gdf_G->transposedAdjList->edge_data) {
      switch (gdf_G->transposedAdjList->edge_data->dtype) {
        case GDF_FLOAT32:
          settype = CUDA_R_32F;
          NVG_TRY(nvgraphAttachEdgeData(nvg_handle,
                                        *nvg_G,
                                        0,
                                        settype,
                                        (float * ) gdf_G->transposedAdjList->edge_data->data))
          break;
        case GDF_FLOAT64:
          settype = CUDA_R_64F;
          NVG_TRY(nvgraphAttachEdgeData(nvg_handle,
                                        *nvg_G,
                                        0,
                                        settype,
                                        (double * ) gdf_G->transposedAdjList->edge_data->data))
          break;
        default:
          return GDF_UNSUPPORTED_DTYPE;
      }
    }

  }
  else {
    // convert edgeList to adjList
    if (gdf_G->adjList == nullptr) {
      GDF_TRY(gdf_add_adj_list(gdf_G));
    }
    TT = NVGRAPH_CSR_32;
    nvgraphCSRTopology32I_st topoData;
    topoData.nvertices = gdf_G->adjList->offsets->size - 1;
    topoData.nedges = gdf_G->adjList->indices->size;
    topoData.source_offsets = (int *) gdf_G->adjList->offsets->data;
     topoData.destination_indices = (int *) gdf_G->adjList->indices->data;
 
    // attach adj list
    NVG_TRY(nvgraphAttachGraphStructure(nvg_handle, *nvg_G, (void * )&topoData, TT));
    //attach edge values
    if (gdf_G->adjList->edge_data) {
      switch (gdf_G->adjList->edge_data->dtype) {
        case GDF_FLOAT32:
          settype = CUDA_R_32F;
          NVG_TRY(nvgraphAttachEdgeData(nvg_handle,
                                        *nvg_G,
                                        0,
                                        settype,
                                        (float * ) gdf_G->adjList->edge_data->data))
          break;
        case GDF_FLOAT64:
          settype = CUDA_R_64F;
          NVG_TRY(nvgraphAttachEdgeData(nvg_handle,
                                        *nvg_G,
                                        0,
                                        settype,
                                        (double * ) gdf_G->adjList->edge_data->data))
          break;
        default:
          return GDF_UNSUPPORTED_DTYPE;
      }
    }
  }
  return GDF_SUCCESS;
}
