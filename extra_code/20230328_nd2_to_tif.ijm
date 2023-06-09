//ImageJ Macro to convert Leica nd2 project files to individual tiff files
//The macro asks for a source directory that contains the lif files to be converted and then makes a subdirectory of that folder and populates it with the converted tif files


dir = getDirectory("Choose folder with .nd2 files.");
list_nd2 = getFileList(dir);
tiff = dir + File.separator + "Tiffs" + File.separator;
File.makeDirectory(tiff);

setBatchMode(true);

for (i = 0; i < list_nd2.length; i++) {
	if(endsWith(list_nd2[i], ".nd2")){
		//print(dir);
		//print(list_nd2[i]);
		run("Bio-Formats Importer", "open=["+dir+list_nd2[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		name = getTitle();
		nameArray = split(name, ".");
		name = String.join(nameArray, "_");
		saveAs("tiff", tiff + name);
		run("Close All");
		print(name);
	}
}
print("Done");