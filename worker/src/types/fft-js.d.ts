declare module 'fft-js' {
  export type ComplexNumber = [number, number];
  
  export default function fft(input: Float32Array): ComplexNumber[];
}
