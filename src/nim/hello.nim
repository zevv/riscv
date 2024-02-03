
{.emit:"void exit(int c) { while(1); }".}


type
  Uart = object
    data: uint32
    status: uint32

var uart {.volatile} = cast[ptr Uart](0x5000)

uart.data = 'a'.uint32
while uart.status != 0:
  discard

