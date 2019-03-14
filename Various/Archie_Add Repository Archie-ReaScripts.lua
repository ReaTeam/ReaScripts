--[[
   * Description: Add Repository Archie-ReaScripts
   * Version:     1.0
   * Author:      Archie
   * О скрипте:   Добавить репозиторий Archie-ReaScripts
   * Donation:    http://money.yandex.ru/to/410018003906628
   * Changelog:   +  initialе / v.1.0 [150319] 
--]]
    
    
    
    
    ------------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end;
    ------------------------------------------------------------------------------
    
    
    local Repo_Name = "Archie-ReaScripts";
    local Repo_URL = "https://github.com/ArchieScript/Archie_ReaScripts/raw/master/index.xml";
    local ReaPack_Url = "http://reapack.com/user-guide";
    
    
    local function S(x)return string.rep(" ",x)end;
    
    if not reaper.APIExists("ReaPack_GetRepositoryInfo") then;
        local MB = reaper.MB(
                  "Rus:\n\n"..
                  " * Отсутствует расширение ReaPack ! \n"..
                  " * Для установки репозитория "..Repo_Name.."\n"..
                  "    требуется расширение 'ReaPack'. \n".. 
                  " * Перейдите на сайт разработчика 'ReaPack' \n"..
                  "    и скачайте расширение для своей ОС.\n----------\n\n"..
                  "Eng:\n\n"..
                  " * Missing extension 'ReaPack' ! \n"..
                  " * To install the repository "..Repo_Name.."\n"..
                  "    extension required 'ReaPack'. \n"..
                  " * Go to the developer's website 'ReaPack' \n"..
                  "    and download the extension for your OS \n----------\n\n"..
                  S(12).."Перейти на сайт 'ReaPack' ? - OK \n\n"..
                  S(12).."Go to website 'ReaPack' ? - OK ",
                  "Error !",1);
        if MB == 1 then;
            local OS = reaper.GetOS();
            if OS == "OSX32" or OS == "OSX64" then;
                cmd = os.execute('open "'..ReaPack_Url..'"');
            else;
                cmd = os.execute('start "" '..ReaPack_Url);
            end;
            if not cmd then;
                reaper.MB(
                "Rus:\n\n * Не удается получить доступ к сайту.\n----------\n\n"..
                "Eng:\n\n"..
                " * Unable to access the site.\n----------\n\n"
                ,"Error !",0);
            end;    
        end;
        no_undo() return;
    end;
    
    
    local
    retval,url,enabled,autoInstall = reaper.ReaPack_GetRepositoryInfo(Repo_Name);
    
    if retval == true and url == Repo_URL then;
        local MB = reaper.MB(
                   "Rus:\n\n"..
                   " * Репозиторий  '"..Repo_Name.."' уже добавлен! \n"..
                   " * Если скрипты не появились в листе действий,то \n"..
                   "    включите синхронизацию в управлении репозиториями.\n"..
                   "    по пути: \n----------\n\n"..
                   "Eng:\n\n"..
                   " * Repository '"..Repo_Name.."' already added! \n"..
                   " * If the scripts does not appear in the action list,then \n"..
                   "    enable the synchronization in the 'manage repositories' \n"..
                   "    by path:\n----------\n\n"..
                   "Путь / Path: \n\n"..
                   " * Reaper:\n"..S(7).."Extensions / ReaPack / Manage repositories:\n"..
                   S(10).."Options \n "..S(14).."install new packades wheh synchronizing.",
                   Repo_Name,0);
         no_undo() return;
    end;
    
    
    local MB = reaper.MB("Rus:\n\n  *  Добавить репозиторий "..Repo_Name.." ?\n\n"..
                         "Eng:\n\n  *  Add repository"..Repo_Name.." ?\n",Repo_Name,1);
    if MB == 1 then;
    
        local
        retval, Error = reaper.ReaPack_AddSetRepository(Repo_Name,Repo_URL,true,2);
        reaper.ReaPack_ProcessQueue(true);
        local
        retval,url,enabled,autoInstall = reaper.ReaPack_GetRepositoryInfo(Repo_Name);
        if retval == true and url == Repo_URL then;
            local MB = reaper.MB(
                       "Rus:\n\n"..
                       " * Репозиторий  '"..Repo_Name.."' был успешно добавлен. \n"..
                       " * Если скрипты не появились в листе действий,то \n"..
                       "    включите синхронизацию в управлении репозиториями.\n"..
                       "    по пути: \n----------\n\n"..
                       "Eng:\n\n"..
                       " * Repository  '"..Repo_Name.."' was successfully added.. \n"..
                       " * If the scripts does not appear in the action list,then \n"..
                       "    enable the synchronization in the 'manage repositories' \n"..
                       "    by path:\n----------\n\n"..
                       "Путь / Path: \n\n"..
                       " * Reaper:\n"..S(7).."Extensions / ReaPack / Manage repositories:\n"..
                       S(10).."Options \n "..S(14).."install new packades wheh synchronizing.",
                       Repo_Name,0);
             no_undo() return;
        end;
    else;
        no_undo() return;
    end;
