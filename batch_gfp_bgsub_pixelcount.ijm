// ===== Batch GFP: background subtraction + pixel count + large-particle pixels =====
// For each image in a folder:
//   1) Subtract a constant background value (user-specified) from the image
//      (negative values are clipped to 0).
//   2) Count how many pixels are > 0 after subtraction  -> PositivePixels.
//   3) From the subtracted image, create a binary mask of positive pixels,
//      run Analyze Particles, and sum the Area (pixels) of particles with
//      Area >= SizeThresholdPixels -> PixelsInLargeParticles.
//   4) Save all results to one CSV.
//
// CSV columns:
//   Image,
//   TotalPixels,
//   BgSubValue,
//   PositivePixels,
//   FractionPositive,
//   SizeThresholdPixels,
//   PixelsInLargeParticles,
//   NumLargeParticles

macro "Batch GFP: BgSub + PositivePixels + LargeParticles" {

    // ----- Choose input folder -----
    dir = getDirectory("Choose folder with GFP images");
    if (dir == "") exit("No folder selected.");

    // ----- Ask for background subtraction value and particle size threshold -----
    Dialog.create("GFP background and particle size parameters");
    Dialog.addNumber("Background value to subtract from ALL images (e.g. 20000):", 0);
    Dialog.addNumber("Particle size threshold (Area in pixels):", 100);
    Dialog.show();
    bgVal   = Dialog.getNumber();  // constant background subtraction value
    sizeThr = Dialog.getNumber();  // particle area threshold

    // ----- Prepare output CSV -----
    outPath = dir + "GFP_bgSub_" + bgVal + "_pixels_and_largeParticles.csv";
    fp = File.open(outPath);
    print(fp,
        "Image," +
        "TotalPixels," +
        "BgSubValue," +
        "PositivePixels," +
        "FractionPositive," +
        "SizeThresholdPixels," +
        "PixelsInLargeParticles," +
        "NumLargeParticles"
    );

    // ----- Ensure Area is measured in pixels -----
    run("Set Measurements...", "area redirect=None decimal=3");

    // ----- Get file list -----
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

        // ----- Open original image -----
        open(path);
        origTitle = getTitle();

        // Image size
        w = getWidth();
        h = getHeight();
        totalPix = w * h;

        // Work on a duplicate for all processing
        selectWindow(origTitle);
        run("Duplicate...", "title=sub_tmp");
        selectWindow("sub_tmp");
        // Close original; we only keep the subtracted copy
        selectWindow(origTitle);
        close();
        selectWindow("sub_tmp");

        // ----- 1) Subtract constant background -----
        // Negative values are clipped to 0 by ImageJ's "Add..."
        run("Add...", "value=-" + bgVal);

        // Stats after subtraction
        getStatistics(areaSub, meanSub, minSub, maxSub, stdSub);

        // Defaults for outputs
        positivePixels      = 0;
        fractionPositive    = 0.0;
        pixelsLarge         = 0.0;
        numLarge            = 0;

        // If everything is zero after subtraction, no positive pixels or particles
        if (maxSub > 0) {

            // ----- 2) Count positive pixels (> 0) after subtraction -----
            // Create a binary mask of positive pixels: threshold [1 .. maxSub]
            run("Duplicate...", "title=mask_tmp");
            selectWindow("mask_tmp");

            setOption("BlackBackground", true);
            setThreshold(1, maxSub);
            run("Convert to Mask");   // 8-bit binary: 0 (background), 255 (positive)

            hist = newArray(256);
            getRawStatistics(nMaskPix, meanMask, minMask, maxMask, stdMask, hist);
            positivePixels   = hist[255];           // all white pixels (signal > 0)
            fractionPositive = positivePixels / totalPix;

            // ----- 3) Analyze particles on the same binary mask -----
            run("Clear Results");
            // Only keep particles with Area >= sizeThr (in pixels)
            run("Analyze Particles...", "size=" + sizeThr + "-Infinity display clear");
            numLarge = nResults;

            sumArea = 0.0;
            for (r = 0; r < numLarge; r++) {
                sumArea += getResult("Area", r);    // Area in pixels
            }
            pixelsLarge = sumArea;

            resetThreshold();
            close();  // close mask_tmp
        }

        // Close the subtracted image
        selectWindow("sub_tmp");
        close();

        // ----- Write results for this image -----
        print(fp,
            name + "," +
            totalPix + "," +
            bgVal + "," +
            positivePixels + "," +
            fractionPositive + "," +
            sizeThr + "," +
            pixelsLarge + "," +
            numLarge
        );
    }

    setBatchMode(false);
    File.close(fp);

    print("Saved GFP background-subtracted pixel and particle summary to: " + outPath);
}
