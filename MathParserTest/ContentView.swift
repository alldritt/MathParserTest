//
//  ContentView.swift
//  MathParserTest
//
//  Created by Mark Alldritt on 2023-04-18.
//

import SwiftUI
import MathParser


struct VariableItem: Identifiable {
    let id = UUID()
    var name: String
    var value: String
}


struct VariablesView: View {
    @Binding var variables: [VariableItem]
    @FocusState var focusedField: UUID?
    
    var body: some View {
        List {
            ForEach($variables) { $variable in
                HStack {
                    TextField("Name", text: $variable.name)
                        .focused($focusedField, equals: variable.id)
                        // Select All upon focus
                        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                            if let textField = obj.object as? UITextField {
                                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                            }
                        }
                    TextField("Value", text: $variable.value)
                        .multilineTextAlignment(.trailing)
                }
            }
            .onDelete { indexSet in
                variables.remove(atOffsets: indexSet)
            }
        }
        .toolbar { EditButton() }
    }
}


struct ContentView: View {
    @State var expression = "1 + 1 + a"
    @State var impliedMultiplication = false
    @State var variables: [VariableItem] = [VariableItem(name: "a", value: "200")]
    
    @FocusState var focusedVariable: UUID?
    @Environment(\.editMode) private var editMode

    func variableProvider(_ name: String) -> Double? {
        //  Do a case-blind variable lookup
        if let variable = variables.first( where: { variable in
            variable.name.lowercased() == name.lowercased()
        }) {
            return Double(variable.value)
        }
        else {
            return nil
        }
    }
    
    func evaluate() -> String {
        //  Evaluate an expression using the MathParser engine.
        let parser = MathParser(variables: variableProvider,
                                enableImpliedMultiplication: impliedMultiplication)
        
        if let evaluator = parser.parse(expression) {
            let result = evaluator.value
            
            if result.isNaN { // An expression identifer is undefined
                let vars = Array(evaluator.unresolved.variables) +
                            Array(evaluator.unresolved.unaryFunctions) +
                            Array(evaluator.unresolved.binaryFunctions)
                                
                return "unresolved symbols: " + (vars.joined(separator: ", "))
            }
            else {
                return String(evaluator.eval())
            }
        }
        else { // syntax error
            //  TODO: find a means of reporting symtax error location
            return "parse failed"
        }
    }
    
    var body: some View {
        Form {
            Section("Expression") {
                TextField("", text: $expression, axis: .vertical)
                    //.textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .lineLimit(10, reservesSpace: false)
                Toggle("Implied Multiplication", isOn: $impliedMultiplication)
            }
            
            Section(header: HStack {
                Text("Variables")
                Spacer()
                //  Show the Add Variable button when not editing the variables list
                if editMode?.wrappedValue.isEditing == false {
                    Button {
                        let newVariable = VariableItem(name: "unknown", value: "0")
                        
                        variables.append(newVariable)
                        focusedVariable = newVariable.id
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                EditButton()
            }) {
                VariablesView(variables: $variables, focusedField: _focusedVariable)
            }
            
            Section("Result") {
                Text(evaluate())
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
