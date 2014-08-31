logread -S HTML
===============
The state should be printed out as two tables. The first table should be two columns 
and list all of the employees and guests. The second table should be two columns
and list room IDs and occupants. If a room is occupied by more than one person, the 
occupant field should be a comma-separated (with no whitespace) list of the occupants
of that room.

    <html>
    <body>
    <table>
    <tr>
      <th>Employee</th>
      <th>Guest</th>
    </tr>
    <tr>
      <td>Employee1</td>
      <td>Guest1</td>
    </tr>
    </table>
    <table>
    <tr>
      <th>Room ID</th>
      <th>Occupants</th>
    </tr>
    <tr>
      <td>1</td>
      <td>Guest1</td>
    </tr>
    <tr>
      <td>2</td>
      <td>Employee1</td>
    </tr>
    </table>
    </body>
    </html>
