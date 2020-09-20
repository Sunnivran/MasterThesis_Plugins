import os
import sys
import getopt
import time
import shutil

def run_segmentation(model_path, input_path, other_params, output_path):
    print("[SSC] Segmentation started")

    #Segmentation starts here
    time.sleep(10.0)
    
    #Output is saved at the path in output_path
    output_mock_path = os.path.dirname(os.path.abspath(__file__)) + '/output.dcm'
    #os.system("cp "+output_mock_path+" "+output_path)
    shutil.copy2(output_mock_path,output_path)

    print("[SSC] Segmentations completed")


def main(argv):
    #print('Argument List:', argv, "\n")
    model_path = ''
    input_path = ''
    other_params = ''
    output_path = ''

    try:
        opts, args = getopt.getopt(argv, "m:i:p:o:", 
        ["model=", "input=", "params=", "output="])
    except:
        print('[SSC] Script called unsuccessfully. Proper call of script:')
        print('[SSC] Segmentation.py -m <model> -i <input file> -o <output file>')
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-m", "--model"):
            model_path = arg
        elif opt in ("-i", "--input"):
            input_path = arg
        elif opt in ("-p", "--params"):
            other_params = arg
        elif opt in ("-o", "--output"):
            output_path = arg
    
    print("[SSC] Segmentator script:")
    print("[SSC] \tPath to model: ", model_path)
    print("[SSC] \tPath to input: ", input_path)
    print("[SSC] \tOther params: ", other_params)
    print("[SSC] \tPath to output: ", output_path)

    run_segmentation(model_path, input_path, other_params, output_path)

if __name__ == '__main__':
    main(sys.argv[1:])
    
    
