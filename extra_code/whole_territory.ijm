dir1 = File.openDialog("choose image");

//open image again to get the outer territory
		open(dir1);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Set Measurements...", "area mean standard centroid center bounding fit redirect=None decimal=3");
		//set measurements so that an ellipse will be fit to the territory
		title = getTitle();
		selectWindow(title);
		run("Split Channels");
		
		selectWindow(title + " (blue)");
		close(title + " (green)");
		close(title + " (red)");
	
		//set to middle slice
		getDimensions(width, height, channels, slices, frames);
		//if there are multiple slices, set the image to the middle slice
		if(slices > 1){
			setSlice(slices/2);
		}
		run("Gaussian Blur...", "sigma=60");
		
		//Huang2 thresholding doesn't work for mCherry cell fill
		//MaxEntropy seems better for mCherry
		//This auto-thresholds the soma to give a solid shape
		run("Auto Threshold", "method=MaxEntropy white");

		//run analyze particles to get territory into roimanager
		run("Analyze Particles...", "display exclude clear summarize add");
		
		splitName = split(title, ".");
		
		splitPath = split(dir1, File.separator);
		
		dirOutput = File.getParent(dir1);
 
		
		//save the territory as an roi
		roiManager("Select", 0);
		roiManager("Save", dirOutput + File.separator + splitName[0] + "_territory.roi");

		close("Summary");
		close("Results");
		close();
		roiManager("reset");

		//set measurements back to normal
		run("Set Measurements...", "area mean standard centroid center bounding integrated display redirect=None decimal=3");

		//return "saved_roi";