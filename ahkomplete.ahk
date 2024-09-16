; v1 - basic funcitonality
; v1.1 - added ability to use 2 different shortcuts and decide on mouse click before pasting
; v1.2 - added ability to use {tab}
; v1.3 - fix so it doesnt {tab} after last input in the sequence
; v1.4 - fix delete also all submenus at the end

#NoEnv
#Warn
#SingleInstance Force
SetWorkingDir %A_ScriptDir%   
global originalClip

!/::  ; alt+/ for keyboard trigger, pastes where the typing cursor is
  ahkomplete(0)
return

^Rbutton::  ; ctrl+right click for mouse trigger, clicks on the mouse cursor position before pasting
  ahkomplete(1)
return

ahkomplete(clickBefore) {
    ;clickBefore - if 1 then it does a click where the mouse cursor is before doing its thing

    ;init variables
    groupNum := 0
    group := ""
    itemNum := 0

    ;save the last thing you had in clipboard
    global originalClip := clipboard
    clipwait, 1
    sleep, 100

    if (clickBefore = 1){
        click
    }

    ;read "rows"
    FileEncoding, UTF-8
    FileRead, data, data.txt
    Rows := StrSplit(data, "/`r`n")

    for index, element in Rows {
        ;split rows
        details:= StrSplit(element,"|")

        ;sets group and item numbers so they are usable as shortcuts to address them in menu by   
        if (group != details[1]) {
          groupNum := groupNum + 1
          itemNum:= 0
        }
        itemNum := itemNum + 1
        
        group := details[1]     ; Menu item
        item := details[2]      ; subMenu item
        value := details[3]     ; pasted value
        options := details[4]   ; parsing options
       
        if (group != "") {
            ;bind function with a value, this is so its callable from menu
            print := Func("paste").Bind(value)
           
            ; Comments
            ; item is disabled in the context menu 
            if (options = "i") {
                if (item = "" and value = "") {
                    groupNum := groupNum - 1
                } else if (item != "" and value = "") {
                    itemNum := itemNum -1
                }
            } else if (options = "c") {
                ;at the Menu level
                if (item = "" and value = "") {
                    Menu ContextMenu, Add, %group%, % print
                    groupNum := groupNum - 1
                    Menu ContextMenu, disable, %group%
                } else if (item != "" and value = "") {  ;at subMenu level
                    Menu %groupNum%. %group% , Add, %item%, % print 
                    itemNum := itemNum -1         
                    Menu %groupNum%. %group% , Disable, %item%
                } 
            } else if (options = "") { 
                ; if there is no subMenu               
                if (item = "") {
                    Menu ContextMenu, Add, &%groupNum%. %group%, % print
                } else {      
                    Menu %groupNum%. %group% , Add, &%itemNum%. %item%, % print
                    Menu ContextMenu, Add, &%groupNum%. %group%, :%groupNum%. %group%                        
                }
            }                    
        }   
    }
    Menu ContextMenu, Show
    ;Throw away the menu and all submenus
    ;so you dont have to reload script when you edit the data.text 
    loop, groupNum {
        Menu %groupNum%, DeleteAll
    }
    Menu ContextMenu, DeleteAll                                 
}

paste(out) {
    ;if there is {tab} in the value, it splits the value based on it and sends a tab press between each
    if inStr(out, "{tab}") > 0 {
        fields:= StrSplit(out,"{tab}")
        for index, element in fields {
            clipboard = %element% 
            clipwait,1
            sleep, 100
            SendInput ^v
            sleep, 100
            if (index <= (fields.Length()-1)) {   ;so it doesnt tab after the last paste
                sendInput {tab}
            }
        }
        sleep,100
        clipboard = %originalClip%
        clipwait,1
        sleep,100
    } else {
        clipboard = %out%    
        clipwait,1
        sleep, 100
        SendInput ^v
        ;return the thing you had in clipboard before
        sleep,100
        clipboard = %originalClip%
        clipwait,1
        sleep,100
    }
}
