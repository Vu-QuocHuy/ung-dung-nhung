declare namespace JSX {
  type Element = any;
  type ElementClass = any;
  interface ElementAttributesProperty {
    props: any;
  }
  interface ElementChildrenAttribute {
    children: any;
  }
  interface IntrinsicAttributes {
    [key: string]: any;
  }
  interface IntrinsicClassAttributes<T> {
    [key: string]: any;
  }
  interface IntrinsicElements {
    [elemName: string]: any;
  }
}

// Fix for recharts components
declare module "recharts" {
  export class XAxis extends React.Component<any, any> {
    props: any;
  }
  export class YAxis extends React.Component<any, any> {
    props: any;
  }
  export class Tooltip extends React.Component<any, any> {
    props: any;
  }
  export class Line extends React.Component<any, any> {
    props: any;
  }
  export class LineChart extends React.Component<any, any> {
    props: any;
  }
  export class CartesianGrid extends React.Component<any, any> {
    props: any;
  }
  export class ResponsiveContainer extends React.Component<any, any> {
    props: any;
  }
}
