import os,posixpath
exclude = ['list.py','list.txt','tempCodeRunnerFile.py']

with open('./list.txt', "w") as hashlist_file:
    hashlist_file.truncate(0)
    
for path, subdirs, files in os.walk(os.path.dirname(os.path.realpath(__file__))):
    for name in files:
        if name not in exclude:
            file_list = os.path.join(path, name)
            file_list = file_list.replace((os.path.dirname(os.path.realpath(__file__))) + '\\', "")
            file_list = file_list.replace(os.sep, '/')
            print(file_list)
            filelist = open('./list.txt', 'a', encoding="utf8")
            filelist.write("\"" + file_list + "\"," + '\n')
            #filelist.write("<bik path=\"" + file_list + "\"/>" +'\n')
            filelist.close()
