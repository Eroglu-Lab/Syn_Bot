

dir = getDirectory("Choose folder with tiff files.");
list_tiff = getFileList(dir);
png_folder = dir + File.separator + "PNGs" + File.separator;
File.makeDirectory(png_folder);

setBatchMode(true);

for (i = 0; i < list_tiff.length; i++) {
	if(endsWith(list_tiff[i], ".tif")){
		//print(dir);
		//print(list_tiff[i]);
		open(dir+list_tiff[i]);
		name = getTitle();
		nameArray = split(name, ".");
		name = String.join(nameArray, "_");
		saveAs("png", png_folder + name);
		run("Close All");
		print(name);
	}
}
print("Done");