from google_trans_new import google_translator
import time
import requests as r

def google_translate(text):
    """
    Translate the input text to English

    :param text: The input text to be translated
    :param dest: The target translation language
    :return: The translation result
    """

    # check to see if the input data type is valid
    if isinstance(text,str):
        # try to translate the text with the google translator API
        for i in range(10):
            try:
                # return the result if no error(s) is encountered
                translator = google_translator()  
                translated_text = translator.translate(text,lang_tgt='en')  
                return translated_text
            except:
                # pause for 2 seconds before re-trying if an error is encountered
                time.sleep(2)
                # print an error message on the 10th failed attempt and return float('nan)
                if i == 9:
                    print(f"--------------Translation Error:{text}--------------")
                    return float('nan')
                pass
    else:
        print('Invalid Input. The input parameter `text` must be string.')
        return float('nan')