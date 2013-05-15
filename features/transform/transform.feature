Feature: Transformer

  The transformer takes a schema, a set of data files, and a list of rules, and
  it produces a structured data tree as output. It depends on a backend which
  must be provided externally.

  Scenario:

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
        <schema name="output">
          <id>
            <text name="name"/>
          </id>
          <fields>
            <text name="value"/>
          </fields>
        </schema>
      </data>
      """

    And a file "input/data.xml":
      """
      <data>
        <input name="name" value="value"/>
      </data>
      """

    And a file "rules/rule.rb":
      """
      # (: in input :)
      # (: out output :)
      require "xml"
      include XML
      proc do
        |hq|
        hq.find("input").each do
          |input|
          output = Node.new "output"
          output["name"] = input["name"]
          output["value"] = input["value"].upcase
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

    When I invoke transform with "default.args"

    Then there should be a file "output/data/output/name.xml":
      """
      <output name="name" value="VALUE"/>
      """
