// ===== Batch DAPI cell counting macro (file-based CSV, robust to inverted masks) =====
macro "Batch DAPI Cell Count" {

    // ----- Choose input folder -----
    dir = getDirectory("Choose folder with DAPI images");
    if (dir == "") exit("No folder selected.");

    // ----- Prepare output CSV -----
    outPath = dir + "DAPI_cell_counts_summary.csv";
    fp = File.open(outPath);
    // Header row
    print(fp, "Image,Raw_Particles,Median_Area_px,EstimatedCells");

    // Make sure we measure area
    run("Set Measurements...", "area redirect=None decimal=3");

    // For checking mask orientation
    maskHist = newArray(256);

    // Get file list
    list = getFileList(dir);

    setBatchMode(true);

    for (i = 0; i < list.length; i++) {
        name = list[i];
        path = dir + name;

        // Skip subfolders
        if (File.isDirectory(path)) continue;

        // Process only typical image types
        if (!endsWith(name, ".tif") && !endsWith(name, ".TIF") &&
            !endsWith(name, ".tiff") && !endsWith(name, ".TIFF") &&
            !endsWith(name, ".png") && !endsWith(name, ".PNG") &&
            !endsWith(name, ".jpg") && !endsWith(name, ".JPG")) {
            continue;
        }

        // ----- Open image -----
        open(path);

        // ----- Convert to binary mask -----
        setOption("BlackBackground", true);   // we want background black *after* we're done
        run("Convert to Mask");               // uses current threshold

        // ----- Auto-fix inverted masks -----
        // If the mask is mostly white (high mean), it's likely background=white, nuclei=black
        getRawStatistics(nPixMask, meanMask, minMask, maxMask, stdMask, maskHist);
        if (meanMask > 128) {
            // Invert so nuclei become white on black background
            run("Invert");
        }

        // ----- Analyze particles on the corrected mask -----
        run("Clear Results");
        run("Analyze Particles...", "display exclude clear");

        n = nResults;

        medianArea     = 0;
        estimatedCells = 0;

        if (n > 0) {
            // Compute median particle area
            medianArea = computeMedianArea(n);

            if (n < 5 || medianArea == 0) {
                // Not enough data for smart splitting – just use raw count
                estimatedCells = n;
            } else {
                // Split large particles based on area relative to median
                cells = 0;
                for (j = 0; j < n; j++) {
                    area   = getResult("Area", j);
                    factor = area / medianArea;

                    // Round to nearest integer, at least 1
                    count = floor(factor + 0.5);
                    if (count < 1) count = 1;

                    cells += count;
                }
                estimatedCells = cells;
            }
        }

        // ----- Append one line to the CSV for this image -----
        print(fp,
            name + "," +
            n + "," +
            medianArea + "," +
            estimatedCells
        );

        // Close mask/image
        close();
    }

    setBatchMode(false);

    // Close CSV
    File.close(fp);

    print("Saved DAPI summary to: " + outPath);
}

// ----- Helper function: median of the 'Area' column in Results -----
function computeMedianArea(n) {
    a = newArray(n);
    for (k = 0; k < n; k++)
        a[k] = getResult("Area", k);

    Array.sort(a);

    if ((n % 2) == 1)
        return a[(n - 1) / 2];
    else
        return (a[n/2 - 1] + a[n/2]) / 2.0;
}
