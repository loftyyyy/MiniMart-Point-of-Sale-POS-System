include C:\masm32\include\masm32rt.inc

.data

    intro db "Hi guys, welcome to my channel", 13, 10,0
    name_prompt db "What's your name? ", 0
    string db 50 dup(?)
    name_result db "Your name is: ", 0


.code

start:

    push offset intro
    call StdOut

    push offset name_prompt
    call StdOut

    push 50
    push offset string
    call StdIn

    push offset name_result
    call StdOut

    push offset string
    call StdOut

    



end start
