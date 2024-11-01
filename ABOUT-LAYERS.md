# About Layers

> Describes how to build this package layer by layer.

## Layer 1 - primitives

Primitives provide basic support for describing a key-value pair.

### Key names

A key name can be:

- any type of data, such as atoms, strings, integers, maps, lists, etc.
- a special one - `:*`, which means several keys that have same set of key attributes.

### Key attributes

Key attributes describe the key and value.

Available attributes are:

- `:type` - specify the type of value.
- `:required` - specify whether the key is required.
- `:default` - specify the default value of the key.
- `:doc` - specify the doc of the key.
- ...

## Layer 2 - meta specs

A meta spec is the spec of a valid spec.

A meta spec is also key-value pairs, so we can describe it with primitives.

For example:

```text
[
  *: [
    type:
      {:keyword_list,
        [
          type: [
            type: {:custom, Type, :validate_type},
            default: :any,
            doc: "..."
          ],
          required: [
            type: :boolean,
            default: false,
            doc: "..."
          ],
          default: [
            type: :any,
            doc: "..."
          ],
          doc: [
            type: {:type_in, [:string, {:in, [false]}]},
            doc: "..."
          ]
        ]}
  ]
]
```

Above meta spec describes the structure of a valid spec:

- It's a keyword list.
- The key can be any type of data.
- The value should be a keyword list, where following keys are expected.
  - :type
  - :required
  - :default
  - :doc

## Layer 3 - specs

A spec is for validating data.

It conforms the meta spec above.

For example:

```text
[
  name: [
    type: :string,
    required: true,
    doc: "The name of server"
  ],
  enabled?: [
    type: :boolean,
    required: false,
    default: true,
    doc: "Whether the server is enabled."
  ],
]
```

## Layer 4 - validator

Validator is for validating that:

- spec follows meta spec.
- data follows spec.

The chain of validation is:

```text
   [meta_spec]
        |
        |
[spec] ---> validated spec
     validate   |
                |
        [data] ---> validated data
             validate
```
