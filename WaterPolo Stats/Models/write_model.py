xml_content = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="1" systemVersion="11A491" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="">
    <entity name="Game" representedClassName="Game" syncable="YES">
        <attribute name="awayTeamId" optional="YES" attributeType="UUID"/>
        <attribute name="date" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="homeTeamId" optional="YES" attributeType="UUID"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="location" optional="YES" attributeType="String"/>
        <attribute name="seasonId" optional="YES" attributeType="UUID"/>
        <attribute name="status" optional="YES" attributeType="String"/>
        <relationship name="awayTeam" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Team" inverseName="awayGames" inverseEntity="Team"/>
        <relationship name="events" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="GameEvent" inverseName="game" inverseEntity="GameEvent"/>
        <relationship name="homeTeam" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Team" inverseName="homeGames" inverseEntity="Team"/>
        <relationship name="rosters" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="GameRoster" inverseName="game" inverseEntity="GameRoster"/>
        <relationship name="season" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Season" inverseName="games" inverseEntity="Season"/>
    </entity>
    <entity name="GameEvent" representedClassName="GameEvent" syncable="YES">
        <attribute name="eventType" optional="YES" attributeType="String"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="period" optional="YES" attributeType="Integer 16" defaultValueString="1" usesScalarValueType="YES"/>
        <attribute name="periodTime" optional="YES" attributeType="String"/>
        <attribute name="timestamp" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <relationship name="game" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Game" inverseName="events" inverseEntity="Game"/>
        <relationship name="player" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Player" inverseName="events" inverseEntity="Player"/>
    </entity>
    <entity name="GameRoster" representedClassName="GameRoster" syncable="YES">
        <attribute name="capNumber" optional="YES" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="enteredGameAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="exitedGameAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="isGoalie" optional="YES" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="isHomeTeam" optional="YES" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="rosterOrder" optional="YES" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <relationship name="game" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Game" inverseName="rosters" inverseEntity="Game"/>
        <relationship name="player" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Player" inverseName="rosters" inverseEntity="Player"/>
    </entity>
    <entity name="Player" representedClassName="Player" syncable="YES">
        <attribute name="createdAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="dateOfBirth" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="name" optional="YES" attributeType="String"/>
        <attribute name="nscaId" optional="YES" attributeType="String"/>
        <attribute name="number" optional="YES" attributeType="String"/>
        <attribute name="profilePhoto" optional="YES" attributeType="Binary"/>
        <attribute name="updatedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <relationship name="events" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="GameEvent" inverseName="player" inverseEntity="GameEvent"/>
        <relationship name="rosters" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="GameRoster" inverseName="player" inverseEntity="GameRoster"/>
        <relationship name="team" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Team" inverseName="players" inverseEntity="Team"/>
    </entity>
    <entity name="Season" representedClassName="Season" syncable="YES">
        <attribute name="endDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="isActive" optional="YES" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="startDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="year" optional="YES" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES"/>
        <relationship name="games" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="Game" inverseName="season" inverseEntity="Game"/>
    </entity>
    <entity name="Team" representedClassName="Team" syncable="YES">
        <attribute name="clubName" optional="YES" attributeType="String"/>
        <attribute name="createdAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="id" optional="YES" attributeType="UUID"/>
        <attribute name="isActive" optional="YES" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="level" optional="YES" attributeType="String"/>
}