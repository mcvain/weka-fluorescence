/*
 * FYP Image Processing Tool (with cyst) 
 */
 
// User inputs
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ File (label = "Classifier") classifier
#@ File (label = "Classifier") cyst_classifier
#@ Boolean (label = "Save generated .roi files in input directory?") roisave

// Initialize
var xcor = "";
var ycor = "";
run("Clear Results");

print("Working directory: " + input);

processFolder(input);

// Scan directory to find files with the correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			labelROI(input, output, list[i]);
	}
}

// Trainable Weka Segmentation workflow to draw the scaffold ROI 
function labelROI(input, output, file) {
	list = getFileList(input); 
	list = Array.sort(list); 
	if (indexOf(file, "ch03.tif") >= 0) {
		print("Opening: " + input + File.separator + file);
		open(input + File.separator + file);

		run("Enhance Contrast", "saturated=0.35");
		run("8-bit");
		run("Scale...", "x=0.0625 y=0.0625 interpolation=Bicubic average create"); // downsample
		run("Set Scale...", "distance=147 known=100 unit=um"); // set scale
		
		run("Trainable Weka Segmentation");
		selectWindow("Trainable Weka Segmentation v3.2.34"); // update this line if Weka gets an update
		wait(500);
		call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier); 
		
		logString = getInfo("log"); 
		while (substring(logString, 0, 23) == "Loading Weka classifier") {
		// put nothing here, process does not proceed until done loading classifier
		};

		wait(2000);
		print("Load classifier... OK");

		call("trainableSegmentation.Weka_Segmentation.getResult");
		logString = getInfo("log"); 
		while (substring(logString, 0, 29) == "Classifying whole image using") {
		// put nothing here, process does not proceed until done classifying image	
		};

		wait(2000); // in case of invoking java error, close background programs and/or try increasing this value
		selectWindow("Classified image");
		print("Classify image... OK");
		
		setTool("wand");

		// set starting point of wand scan as the middle of the image
		xcor = getWidth() / 2; 
		ycor = getHeight() / 2;

		// initialize scanning variables
		classarray = classcheck();
		classvar = classarray[0]; 
		areavar = classarray[1];

		// Scanning for the correct ROI
		while (classvar == 0 || areavar < 3000) { 	// runs if selected area is non-scaffold OR too small (units in default)
			if (ycor < 0.9 * getHeight()) { 		// move y position of wand downwards until almost at the bottom of the image 
				ycor = ycor + 5; 
				classarray = classcheck();
				classvar = classarray[0];
				areavar = classarray[1];
				IJ.deleteRows(nResults-1, nResults-1); 
			}

			else {
				ycor = ycor - 5; 					// then, move it back up 
				classarray = classcheck();
				classvar = classarray[0];
				areavar = classarray[1];
				IJ.deleteRows(nResults-1, nResults-1);
			}

		};
		IJ.deleteRows(nResults-1, nResults-1); // removes last line of classcheck temporary measurement left over
		
		print("Finalize Scaffod ROI... OK"); 
		
		roiManager("deselect");
		roiManager("delete"); // clear ROIs
		
		roiManager("Add"); // apply the finalized ROI
		roiManager("Select", 0); 
		roiManager("Rename", "scaf");
		// roiManager("Rename", "prod" + "-" + substring(file, lengthOf(file) - 17, lengthOf(file) - 10)); // label ROI with section number
		selectWindow("Classified image");
		close(); 
		
		selectWindow("Trainable Weka Segmentation v3.2.34"); // update this line if Weka gets an update
		wait(500);
		call("trainableSegmentation.Weka_Segmentation.loadClassifier", cyst_classifier);

		logString = getInfo("log"); 
		while (substring(logString, 0, 23) == "Loading Weka classifier") {
		// put nothing here, process does not proceed until done loading classifier
		};

		wait(2000);
		print("Load classifier... OK");

		call("trainableSegmentation.Weka_Segmentation.getResult");
		logString = getInfo("log"); 
		while (substring(logString, 0, 29) == "Classifying whole image using") {
		// put nothing here, process does not proceed until done classifying image	
		};

		wait(2000); // in case of invoking java error, close background programs and/or try increasing this value
		selectWindow("Classified image");
		print("Classify image... OK");
		
		setTool("wand");

		// set starting point of wand scan as the middle of the image
		xcor = getWidth() / 2; 
		ycor = getHeight() / 2;

		// initialize scanning variables
		classarray = classcheck();
		classvar = classarray[0]; 
		areavar = classarray[1];

		// Scanning for the correct ROI
		while (ycor > getHeight() / 2) {
			ycor = ycor - 5; // move y up 
			classarray = classcheck(); 
			classvar = classarray[0]; 
			areavar = classarray[1];
			IJ.deleteRows(nResults-1, nResults-1);
			if (classvar == 0) {
				roiManager("Add");
				roiManager("Rename", "rostral-cyst");
				run("Measure");
			}
		};
		while (ycor < getHeight() / 2) {
			ycor = ycor + 5;
			classarray = classcheck();
			classvar = classarray[0];
			areavar = classarray[1];
			IJ.deleteRows(nResults-1, nResults-1); 
			if (classvar == 0) {
				roiManager("Add");
				roiManager("Rename", "caudal-cyst");
				run("Measure");
			}
			
		};
			
		IJ.deleteRows(nResults-1, nResults-1); // removes last line of classcheck temporary measurement left over
		
		print("Finalize Cyst ROI... OK");
		print("Ready to measure NF... OK");
		
		measureNF(input, output, file); 
	} 
}

// Measuring NF200 signal with RATS
function measureNF(input, output, file) {
	target = substring(file, 0, lengthOf(file) - 8);
	target = target + "ch01.tif";
	print("Opening: " + input + File.separator + target);
	open(input + File.separator + target); 

	roiManager("select", 0); // this should select the scaf ROI
	run("Scale... ", "x=16 y=16");
	roiManager("update");

	if (roisave == true) {
		roiManager("save selected", input + File.separator + substring(target, 0, lengthOf(target) - 9) + ".roi");
	};
	
	run("8-bit");
	run("Robust Automatic Threshold Selection", "noise=3.5 lambda=2 min=75 verbose");
	rename(target + "-threshold");
	
	run("Set Scale...", "distance=147 known=100 unit=um");

	roiManager("select", 0);

	run("Set Measurements...", "area min integrated area_fraction limit display redirect=None decimal=3");
	run("Measure");
	
	roiManager("deselect"); // command after deselect applies to all ROIs
	roiManager("Delete");

	// re-set the windows 
	selectWindow("Trainable Weka Segmentation v3.2.34"); // update this line if Weka gets an update
	close();
	selectWindow(target + "-threshold"); 
	close(); 
	selectWindow(target);
	close();
	selectWindow(file);
	close(); 
	
};

function classcheck() {
	setTool("wand");
	doWand(xcor, ycor);
	roiManager("Add");
	run("Set Measurements...", "area modal min integrated area_fraction limit display redirect=None decimal=3");
	run("Measure");

	output = newArray(getResult("Mode"), getResult("Area"));
	return output;
};

print("All measurements complete."); 