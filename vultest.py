#!/usr/bin/env python
# -*- coding: utf-8 -*-

def CIRCL_cve_search(cve):
    circl_url = 'http://cve.circl.lu/api/cve'
    cve_search_url = circl_url + '/' + cve
    r = requests.get(cve_search_url)
    print(r)
    #print (json.dumps(r.json(), sort_keys=True, indent=2))

    l = json.dumps(r.json(), indent=2)
    cve_dict = json.loads(l)
    print(cve_dict["access"]["vector"])


def main():
    cve = input()
    CIRCL_cve_search(cve)

if __name__ == '__main__':
    main()
