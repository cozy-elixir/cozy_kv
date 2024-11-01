# Design

## Level 1 - primitives

Defines the basic attributes to describe key-value pairs.

- `type` - `:any` / `nil` / `:integer` / ...
- `required`
- `default`
- `doc`
- ...

## Level 2 - value specs

Defines the shape of values.

For example:

```text
[
  type: :boolean,
  required: false,
  default: true,
  # ...
]
```

## Level 3 - specs

Defines the shape of key-value pairs.

They are keys + value specs.

For example:

```text
[
  name: [
    type: :string,
    required: true,
    # ...
  ],
  enabled?: [
    type: :boolean,
    required: false,
    default: true,
    # ...
  ],
  # ...
]
```

## Use cases

### specs for describing specs

A spec is able to describe another spec.

For example:

```
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

> Above spec expects a piece of data, which is a keyword list.
> In the keyword list, following keys are expected:
>
> - :type
> - :required
> - :default
> - :doc

### specs for describing data

It's the same as "Level 3 - specs".
