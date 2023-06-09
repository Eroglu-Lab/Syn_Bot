//ImageJ Macro to convert Leica lif project files to individual tiff files
//The macro asks for a source directory that contains the lif files to be converted and then makes a subdirectory of that folder and populates it with the converted tif files
//@author Juan Ramirez
//01/26/23

dir = getDirectory("Choose folder with .lif files.");
list_lif = getFileList(dir);
tiff = dir + File.separator + "Tiffs" + File.separator;
File.makeDirectory(tiff);

setBatchMode(true);

for (i = 0; i < list_lif.length; i++) {
	if(endsWith(list_lif[i], ".lif")){
		run("Bio-Formats Macro Extensions");
   		Ext.setId(dir+list_lif[i]);
   		Ext.getSeriesCount(seriesCount);
   		sCount=seriesCount;
   		//print(sCount);
   		for (x = 0; x < sCount; x++) {
   			current_series_num = x+1;
   			current_series = "series" + "_" +current_series_num;
   			//print(current_series);
   			run("Bio-Formats Importer", "open=["+dir+list_lif[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT "+current_series+"");
			name = getTitle();
			nameArray = split(name, ".");
			name = String.join(nameArray, "_");
			saveAs("tiff", tiff + name);
			run("Close All");
			print(name);
   		}
	}
}
print("Done");