package sc.fiji.coloc_calc;

import ij.IJ;

import ij.measure.ResultsTable;
import ij.plugin.PlugIn;
import ij.plugin.filter.Analyzer;

/**
 * Main class.
 * This class is a plugin for the ImageJ interface for calculating colocalizations within
 * the puncta analyzer macro
 *
 * 
 * @author Justin Savage (justin.savage at duke.edu)
 *
 */
public class Coloc_Calc implements PlugIn {

	@Override
	public void run(String arg) {
		// TODO Auto-generated method stub

		if (IJ.isResultsWindow() == false) {
			//TODO throw error 
		}

		//Analyzer a = new Analyzer();
		ResultsTable rt = Analyzer.getResultsTable(); // get the system results table
		double[] redX = rt.getColumnAsDoubles(rt.getColumnIndex("redX"));
		double[] redY = rt.getColumnAsDoubles(rt.getColumnIndex("redY"));
		double[] redR = rt.getColumnAsDoubles(rt.getColumnIndex("redR"));
		double[] greenX = rt.getColumnAsDoubles(rt.getColumnIndex("greenX"));
		double[] greenY = rt.getColumnAsDoubles(rt.getColumnIndex("greenY"));
		double[] greenR = rt.getColumnAsDoubles(rt.getColumnIndex("greenR"));

		int redCount = redX.length;
		int greenCount = greenX.length;

		double[] colocX = new double[10000];
		double[] colocY = new double[10000];
		double[] colocAreaArray = new double[10000];
		int colocCount = 0; 

		//for each red puncta
		for (int i = 0; i < redCount; i++) {

			//for each green puncta
			for (int j = 0; j < greenCount; j++) {
				double colocA = colocArea(redX[i], redY[i], redR[i], greenX[j], greenY[j], greenR[j]);
				if (colocA > 0) {
					//stores the x and y coordinates of the colocalized
					//puncta, using midpos to get an integer
					colocX[colocCount] = midpos(redX[i], greenX[j]);
					colocY[colocCount] = midpos(redY[i], greenY[j]);
					colocAreaArray[colocCount] = colocA;
					colocCount = colocCount + 1;
				}
			}
		}

		int colocXTrueLength = 0;
		for (int i = 0; i < colocX.length; i++) {
			if (colocX[i] != 0) {
				colocXTrueLength = i;
			}
			else {
				break;
			}
		}

		int colocYTrueLength = 0;
		for (int i = 0; i < colocY.length; i++) {
			if (colocY[i] != 0) {
				colocYTrueLength = i;
			}
			else {
				break;
			}
		}

		double[] colocXOut = new double[colocXTrueLength];
		double[] colocYOut = new double[colocYTrueLength];

		for(int i = 0; i < colocXTrueLength; i++) {
			colocXOut[i] = colocX[i];
		}

		for(int i = 0; i < colocYTrueLength; i++) {
			colocYOut[i] = colocY[i];
		}

		ResultsTable rtOut = new ResultsTable();

		for(int n = 0; n < colocXOut.length; n++) {
			rtOut.incrementCounter();
			rtOut.addValue("n", n);
			rtOut.addValue("colocX", colocXOut[n]);
			rtOut.addValue("colocY", colocYOut[n]);
			rtOut.addValue("colocArea", colocAreaArray[n]);
		}
		
		IJ.renameResults("Results", "oldResults");
		
		rtOut.show("Results");
		//Analyzer.setResultsTable(rt);
		//a.displayResults(); 
	}

	public double midpos (double a, double b) {
		return ((a + b)/2 + 1);
	}

	//Calculates the intersectional area of two puncta to get the area of the colocalization
	//based on https://www.xarg.org/2016/07/calculate-the-intersection-area-of-two-circles/ 
	public double colocArea (double xa, double ya, double ra, double xb, double yb, double rb) {

		double d = Math.sqrt(Math.pow((yb - ya), 2) + Math.pow(xb - xa, 2));

		if (d < ra + rb) {

			double a = ra * ra;
			double b = rb * rb;

			double x = (a - b + d * d) / (2 * d);
			double z = x * x;
			double y = Math.sqrt(a - z);

			if (d <= Math.abs(rb - ra)) {
				return Math.PI * Math.min(a, b);
			}
			return a * Math.asin(y / ra) + b * Math.asin(y / rb) - y * (x + Math.sqrt(z + b - a));
		}
		return 0;
	}

}

	


