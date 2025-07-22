export class ByteArrayStream {
  private buffer: Uint8Array;
  private position: number;

  constructor(data: Uint8Array) {
    this.buffer = data;
    this.position = 0;
  }

  // 读取一个字节
  readByte(): number | null {
    if (this.position < this.buffer.length) {
      return this.buffer[this.position++];
    }
    return null; // 数据结束
  }

  // 向流中写入字节
  writeByte(byte: number): void {
    if (this.position < this.buffer.length) {
      this.buffer[this.position++] = byte;
    } else {
      // 如果超过了缓冲区的大小，可以增加缓冲区的大小
      const newBuffer = new Uint8Array(this.buffer.length + 1);
      newBuffer.set(this.buffer);
      newBuffer[this.position] = byte;
      this.buffer = newBuffer;
      this.position++;
    }
  }

  writeBytes(bytes: Uint8Array): void {
    bytes.forEach((byte) => {
      this.writeByte(byte)
    })
  }

  // 读取多个字节
  readBytes(length: number): Uint8Array {
    this.setPosition(0);
    const end = Math.min(this.position + length, this.buffer.length);
    const result = this.buffer.slice(this.position, end);
    this.position = end;
    return result;
  }

  // 获取当前位置
  getPosition(): number {
    return this.position;
  }

  // 设置当前位置
  setPosition(pos: number): void {
    if (pos >= 0 && pos <= this.buffer.length) {
      this.position = pos;
    } else {
      throw new Error("Invalid position");
    }
  }

  // 获取流的总长度
  getLength(): number {
    return this.buffer.length;
  }
}