//ImageJ Macro to convert Olympus oir images to individual tiff files
//The macro asks for a source directory that contains the lif files to be converted and then makes a subdirectory of that folder and populates it with the converted tif files


dir = getDirectory("Choose folder with .oir files.");
list_oir = getFileList(dir);
tiff = dir + File.separator + "Tiffs" + File.separator;
File.makeDirectory(tiff);

setBatchMode(true);

for (i = 0; i < list_oir.length; i++) {
	if(endsWith(list_oir[i], ".oir")){
		//print(dir);
		//print(list_oir[i]);
		run("Bio-Formats Importer", "open=["+dir+list_oir[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		name = getTitle();
		nameArray = split(name, ".");
		name = String.join(nameArray, "_");
		saveAs("tiff", tiff + name);
		run("Close All");
		print(name);
	}
}
print("Done");