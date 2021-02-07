from random import randint
import time
from os import listdir
import requests as r

from bs4 import BeautifulSoup as soup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys


def get_user_agent():
    user_agent_list_txt = open("./utility/user_agent_list.txt", "r").read()
    user_agent_list = user_agent_list_txt.split('\n')
    # get the length of the user agent list
    len_list = len(user_agent_list) - 1
    # randomly choose a user agent from the list
    list_index = randint(1, len_list)
    user_agent = user_agent_list[list_index]
    return(user_agent)

def request_session(url):
    s = r.Session()
    for i in range(3):
        ua = get_user_agent()
        s.headers.update({'user-agent': ua})
        response = s.get(url)
        time.sleep(randint(0,2))
        status_code = response.status_code
        if status_code == 200:
            return({'content': response.content, 'status_code': status_code, 'text':response.text})
    print(status_code)
    return float('nan')

# parse the HTML of the page
def get_page(url):

    for i in range(3):
        try:
            print('making html request:'+url)
            # get the page and page type
            response = request_session(url)
            page_soup = soup(response['content'],"html.parser")
            return page_soup
        except Exception as e:
            if i==2:
                print(e)
                raise
            time.sleep(randint(2,4))
            pass
    return float('nan')


def change_ua_selenium_options(user_agent, options):
    # if there is already a "user-agent" argument in options delete it
    for item in options.arguments:
        if '--user-agent=' in item:
            options.arguments.remove(item)
    # add generated user-agent to options
    options.add_argument(f'--user-agent={user_agent}')

def get_page_selenium(url):
    # get the company profile url based on the company name
    for i in range(3):
        try:
            # initialize chrome options
            options = webdriver.ChromeOptions()
            options.add_experimental_option('useAutomationExtension', False)
            options.add_argument("--headless")
            # apply chrome options
            driver = webdriver.Chrome(options=options,executable_path='./utility/chromedriver')
            # change user agent
            change_ua_selenium_options(get_user_agent(), options)
            # load the url
            driver.get(url)
            driver.set_window_size(1920, 1080)
            # close possibe pop ups
            for i in range(2):
                time.sleep(randint(1,2))
                webdriver.ActionChains(driver).send_keys(Keys.ESCAPE).perform()
            # get scroll height
            last_height = driver.execute_script("return document.body.scrollHeight")
            # scroll to the bottom of the page
            while True:
                # scroll down to bottom
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                # wait to load page
                time.sleep(3)
                # calculate new scroll height and compare with last scroll height
                new_height = driver.execute_script("return document.body.scrollHeight")
                if new_height == last_height:
                    break
                last_height = new_height
            # parse the HTML of the page
            page = soup(driver.page_source, "html.parser")
            driver.close()
            return page
        except:
            time.sleep(randint(2,3))
            pass