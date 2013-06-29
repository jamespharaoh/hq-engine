@temp-dir
Feature: Transformer

  The transformer takes a schema, a set of data files, and a list of rules, and
  it produces a structured data tree as output. It depends on a backend which
  must be provided externally.

  Background:

    Given a file "schema.xml":
      """
      <data>

        <schema name="input">

          <id>
            <text name="name"/>
          </id>

          <fields>
            <text name="value"/>
          </fields>

        </schema>

        <schema name="internal">

          <id>
            <text name="name"/>
          </id>

          <fields>
            <text name="value"/>
          </fields>

        </schema>

        <schema name="output">

          <id>
            <text name="name"/>
          </id>

          <fields>
            <text name="value"/>
          </fields>

        </schema>

        <transform
          name="input-to-internal"
          rule="input-to-internal">

          <input name="input"/>
          <output name="internal"/>

          <match type="input">
            <field name="name" as="name"/>
          </match>

        </transform>

        <transform
          name="internal-to-output"
          rule="internal-to-output">

          <input name="internal"/>
          <output name="output"/>

          <match type="internal">
            <field name="name" as="name"/>
          </match>

        </transform>

      </data>
      """

    And a file "input/data.xml":
      """
      <data>
        <input name="name" value="value"/>
      </data>
      """

    And a file "rules/input-to-internal.rb":
      """
      require "xml"

      proc do |hq|

        input = hq.get "input", hq.input["name"]

        internal = XML::Node.new "internal"
        internal["name"] = input["name"]
        internal["value"] = input["value"].upcase

        hq.write internal

      end
      """

    And a file "rules/internal-to-output.rb":
      """
      require "xml"

      proc do |hq|

        internal = hq.get "internal", hq.input["name"]

        2.times do |time|

          output = XML::Node.new "output"
          output["name"] = "#{internal["name"]}-#{time}"
          output["value"] = internal["value"]

          hq.write output

        end

      end
      """

    And a file "default.args":
      """
      --schema schema.xml
      --input input
      --rules rules
      --include include
      --output output
      """

  Scenario: Success

    When I invoke transform with "default.args"

    Then there should be a file "output/data/input/name.xml":
      """
      <input name="name" value="value"/>
      """

    And there should be a file "output/data/internal/name.xml":
      """
      <internal name="name" value="VALUE"/>
      """

    And there should be a file "output/data/output/name-1.xml":
      """
      <output name="name-1" value="VALUE"/>
      """

# vim: et ts=2
