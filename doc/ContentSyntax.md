# Content Syntax

## markdown

All basic Markdown syntax is supported. 

~~~markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

**Bold text**

*Italic text*

~~Strikethrough text~~

[Link text](https://example.com)

- List item 1
- List item 2
- List item 3

1. Ordered item 1
2. Ordered item 2
3. Ordered item 3

> Blockquote

`Inline code`

```python
print('Code block')
```

~~~

For more information, see 
[Markdown Basic Syntax](https://www.markdownguide.org/basic-syntax/).

## html

Only `<img>` is supported to embed a sized image.

```markdown
# html image sample
<img src="https://example.com/image" width="150" height="150">
```

## extended markdown

### Table

```markdown
| Syntax      | Description |
| ----------- | ----------- |
| Header      | Title       |
| Paragraph   | Text        |
```

### Task List

```markdown
- [x] Task 1
- [ ] Task 2
- [ ] Task 3
```

## Math

Math is supported with latex syntax.

```markdown
$O(n) = n^2$
```

## Tag

A tag should start with `#`, the `#` should be the start of line or after a space.
And the tag should be followed by a space or as the end of line.

```markdown
#tag1 #tag2 #tag3
```