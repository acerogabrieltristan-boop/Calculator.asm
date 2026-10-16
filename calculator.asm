# Calculator.asm
section .data
    menu db "----------------------------------",10
         db "MENU",10
         db "[A]dd",10
         db "[S]ubtract",10
         db "[M]ultiply",10
         db "[D]ivide",10
         db "----------------------------------",10
         db "Enter your choice: ",0

    firstPrompt db "Enter first number: ",0
    secondPrompt db "Enter second number: ",0

    sumMsg db "The sum is ",0
    differenceMsg db "The difference is ",0
    productMsg db "The product is ",0
    quotientMsg db "The quotient is ",0
    remainderMsg db "The remainder is ",0

    againPrompt db "Do you want to try again (Y/N): ",0
    invalidChoice db "Invalid choice. Enter A, S, M, or D.",10,0
    invalidNumber db "Enter a whole number from 0 to 99: ",0
    invalidAgain db "Please enter Y or N.",10,0
    zeroMsg db "Cannot divide by zero.",10,0
    exitMsg db "Program terminated.",10,0

    newline db 10,0
    clearScreenCode db 27,"[2J",27,"[H",0

section .bss
    buffer resb 32
    inputChar resb 1
    outputBuffer resb 16
    choice resb 1
    firstNumber resd 1
    secondNumber resd 1
    remainderValue resd 1

section .text
    global _start

_start:
    call clear_screen

menu_loop:
    mov ecx, menu
    call print_string
    call read_line

    cmp eax, 1
    jne invalid_choice

    mov al, [buffer]
    and al, 0DFh

    cmp al, 'A'
    je valid_choice
    cmp al, 'S'
    je valid_choice
    cmp al, 'M'
    je valid_choice
    cmp al, 'D'
    jne invalid_choice

valid_choice:
    mov [choice], al

    mov ecx, firstPrompt
    call print_string
    call read_number
    mov [firstNumber], eax

    mov ecx, secondPrompt
    call print_string
    call read_number
    mov [secondNumber], eax

    mov eax, [firstNumber]
    mov ebx, [secondNumber]

    cmp byte [choice], 'A'
    je addition
    cmp byte [choice], 'S'
    je subtraction
    cmp byte [choice], 'M'
    je multiplication
    jmp division

invalid_choice:
    mov ecx, invalidChoice
    call print_string
    jmp menu_loop

addition:
    call add_numbers
    mov ecx, sumMsg
    call print_string
    call print_integer
    jmp result_done

subtraction:
    call subtract_numbers
    mov ecx, differenceMsg
    call print_string
    call print_integer
    jmp result_done

multiplication:
    call multiply_numbers
    mov ecx, productMsg
    call print_string
    call print_integer
    jmp result_done

division:
    test ebx, ebx
    jz divide_by_zero

    call divide_numbers
    mov [remainderValue], edx

    mov ecx, quotientMsg
    call print_string
    call print_integer

    mov ecx, newline
    call print_string

    mov ecx, remainderMsg
    call print_string
    mov eax, [remainderValue]
    call print_integer
    jmp result_done

divide_by_zero:
    mov ecx, zeroMsg
    call print_string
    jmp ask_again

result_done:
    mov ecx, newline
    call print_string

ask_again:
    mov ecx, againPrompt
    call print_string
    call read_line

    cmp eax, 1
    jne invalid_answer

    mov al, [buffer]
    and al, 0DFh

    cmp al, 'Y'
    je restart
    cmp al, 'N'
    je goodbye

invalid_answer:
    mov ecx, invalidAgain
    call print_string
    jmp ask_again

restart:
    call clear_screen
    jmp menu_loop

goodbye:
    mov ecx, exitMsg
    call print_string

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 80h

add_numbers:
    add eax, ebx
    ret

subtract_numbers:
    sub eax, ebx
    ret

multiply_numbers:
    imul eax, ebx
    ret

divide_numbers:
    xor edx, edx
    div ebx
    ret

print_string:
    pushad
    xor edx, edx

find_length:
    cmp byte [ecx + edx], 0
    je write_string
    inc edx
    jmp find_length

write_string:
    mov eax, 4
    mov ebx, 1
    int 80h
    popad
    ret

clear_screen:
    push ecx
    mov ecx, clearScreenCode
    call print_string
    pop ecx
    ret

read_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor esi, esi
    xor edi, edi

read_character:
    mov eax, 3
    xor ebx, ebx
    mov ecx, inputChar
    mov edx, 1
    int 80h

    cmp eax, 0
    jle exit_program

    mov al, [inputChar]

    cmp al, 10
    je line_finished
    cmp al, 13
    je read_character

    cmp esi, 31
    jae line_overflow

    mov [buffer + esi], al
    inc esi
    jmp read_character

line_overflow:
    mov edi, 1
    jmp read_character

line_finished:
    mov byte [buffer + esi], 0
    mov eax, esi

    test edi, edi
    jz return_line
    mov eax, 32

return_line:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

read_number:
    push ebx
    push ecx
    push edx
    push esi

number_retry:
    call read_line

    cmp eax, 1
    jb number_invalid
    cmp eax, 2
    ja number_invalid

    mov ecx, eax
    xor eax, eax
    xor esi, esi

convert_digit:
    movzx edx, byte [buffer + esi]

    cmp edx, '0'
    jb number_invalid
    cmp edx, '9'
    ja number_invalid

    sub edx, '0'
    imul eax, eax, 10
    add eax, edx

    inc esi
    loop convert_digit

    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

number_invalid:
    mov ecx, invalidNumber
    call print_string
    jmp number_retry

print_integer:
    pushad

    mov edi, outputBuffer + 15
    mov byte [edi], 0
    xor esi, esi

    test eax, eax
    jns convert_integer

    mov esi, 1
    neg eax

convert_integer:
    mov ebx, 10

next_digit:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz next_digit

    test esi, esi
    jz display_integer

    dec edi
    mov byte [edi], '-'

display_integer:
    mov ecx, edi
    call print_string
    popad
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
