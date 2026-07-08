# atypical-EPEC-tools

Code and macros used in the manuscript "Parallel Evolutionary Trajectories Rewire Enteropathogenic Escherichia coli Adhesion to Restore Host Attachment" for analysis of
**atypical enteropathogenic *Escherichia coli* (aEPEC)** attachment evolution and associated image quantification.

This package includes:
1) Two **standalone, browser-based HTML tools** that run fully offline (no external dependencies; no network calls).
2) Two **Fiji/ImageJ macros** for batch quantification of GFP and DAPI microscopy images.

Version: **v1.0.0** (manuscript submission snapshot)

---

## Contents

### Browser tools (offline)
- `code/gb_liftover.html`  
  GenBank liftover (single genome): transfers selected annotations from a reference GenBank file to
  a target genome provided as a folder of GenBank contigs.

- `code/dnds_folder_variants_v12_7.html`  
  Folder-based GenBank variant summary: extracts a specified gene (e.g., **fimH**) across many
  GenBank files, summarizes synonymous/nonsynonymous changes, reports dN/dS-style summaries, and
  infers plausible mutation-accumulation relationships based on intermediate genotypes.

### Fiji/ImageJ macros
- `imagej_macros/batch_dapi_cell_count.ijm`  
  Batch DAPI nuclei counting from a folder of images using thresholding + Analyze Particles,
  reporting per-image particle count and an area-adjusted estimated cell count.

- `imagej_macros/batch_gfp_bgsub_pixelcount.ijm`  
  Batch GFP quantification from a folder of images: subtracts a user-provided constant background,
  computes positive pixel count and fraction positive, and quantifies pixels in particles above a
  minimum size threshold.

---

## Requirements

### Browser tools
- A modern browser. Chromium-based browsers (Chrome/Edge) are recommended.
- No installation required.

### ImageJ macros
- Fiji (recommended) or ImageJ 1.x with Analyze Particles.

---

## How to run

### Browser tools
1. Open the desired `.html` file in your browser (double-click, or drag into a browser window).
2. Select the input file(s)/folder(s) when prompted.
3. Use the Export/Download controls to save outputs.

**Data privacy:** all computation happens locally in your browser; inputs are not uploaded.

### Fiji/ImageJ macros
1. Open Fiji.
2. `Plugins` → `Macros` → `Run...` and select the `.ijm` file.
3. Choose the input folder when prompted.
4. Follow on-screen prompts (background subtraction and particle size threshold for GFP macro).

Outputs are written as CSV files in (or alongside) the chosen input folder.

---

## License
MIT (see `LICENSE`).

---

## How to cite (template)
> Author(s). atypical-epec-tools: offline GenBank utilities and Fiji macros (v1.0.0). DOI: [to be added].

