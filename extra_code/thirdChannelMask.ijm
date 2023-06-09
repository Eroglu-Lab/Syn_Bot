//Asks user for source directory
dir1  = getDirectory("Choose Source Directory ");
list1  = getFileList(dir1);

dir2 = dir1 + "processed_images"+File.separator;
	File.makeDirectory(dir2);

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	file = list1[i];
	print(list1[i]);
	if (endsWith(file, ".tif")){
		open(dir1 + file);
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Select All");
		run("Split Channels");
		//generate mask from blue
		selectWindow(file + " (blue)");
		title = getTitle();
		title = split(title, ".");
		setAutoThreshold("Default dark");
		//run("Threshold...");
		//setThreshold(100, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Create Selection");
		selectWindow(file + " (red)");
		run("Restore Selection");
		setBackgroundColor(0, 0, 0);
		run("Clear Outside");
		
		selectWindow(file + " (blue)");
		
		selectWindow(file + " (green)");
		run("Restore Selection");
		run("Clear Outside");
		run("Merge Channels...", "c1=[" +file + 
		" (red)] c2=[" + file + " (green)] create");
		saveAs("Tiff", dir2 + title[0] + "_clear_out");
		close("*");

	}

	if (endsWith(file, ".tif")){
		open(dir1 + file);
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Select All");
		run("Split Channels");
		//generate mask from blue
		selectWindow(file + " (blue)");
		title = getTitle();
		title = split(title, ".");
		setAutoThreshold("Default dark");
		//run("Threshold...");
		//setThreshold(100, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Create Selection");
		selectWindow(file + " (red)");
		run("Restore Selection");
		setBackgroundColor(0, 0, 0);
		run("Clear");

		
		selectWindow(file + " (blue)");
		
		selectWindow(file + " (green)");
		run("Restore Selection");
		run("Clear");
		run("Merge Channels...", "c1=[" +file + 
		" (red)] c2=[" + file + " (green)] create");
		saveAs("Tiff", dir2 + title[0] + "_clear_in");
		close("*");

	}
	
}